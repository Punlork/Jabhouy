package com.pl.shop.management

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.text.DecimalFormat
import java.util.concurrent.Executors

object BankNotificationPushDispatcher {
    private const val cookiePrefsKey = "flutter.cookies"
    private const val nativeBaseUrlKey = "flutter.income_sync_api_base_url"
    private const val sharedPrefsName = "FlutterSharedPreferences"

    private val executor = Executors.newSingleThreadExecutor()

    fun dispatchImmediatelyIfFlutterInactive(context: Context, payload: JSONObject) {
        if (NotificationTrackingBridge.hasActiveFlutterListener()) {
            NotificationTrackingBridge.appendDiagnosticLog(
                context = context,
                source = "android.push_dispatcher",
                message = "Skipped immediate native push because Flutter listener is active.",
                metadata = mapOf(
                    "fingerprint" to payload.optString("fingerprint"),
                ),
            )
            return
        }

        executor.execute {
            val fingerprint = payload.optString("fingerprint")
            if (fingerprint.isNotBlank() &&
                NotificationTrackingBridge.isFingerprintUploaded(context, fingerprint)
            ) {
                NotificationTrackingBridge.appendDiagnosticLog(
                    context = context,
                    source = "android.push_dispatcher",
                    message = "Skipped immediate native push because this fingerprint was already uploaded.",
                    metadata = mapOf(
                        "fingerprint" to fingerprint,
                    ),
                )
                return@execute
            }

            if (!NotificationTrackingBridge.isMainDevice(context)) {
                NotificationTrackingBridge.appendDiagnosticLog(
                    context = context,
                    source = "android.push_dispatcher",
                    message = "Skipped immediate native push because this device is not the main device.",
                    level = "warning",
                    metadata = mapOf(
                        "fingerprint" to payload.optString("fingerprint"),
                    ),
                )
                return@execute
            }

            try {
                sendPayload(context, payload)
                payload.optString("fingerprint")
                    .takeIf { it.isNotBlank() }
                    ?.let { fingerprint ->
                        NotificationTrackingBridge.markUploaded(context, listOf(fingerprint))
                    }
                NotificationTrackingBridge.appendDiagnosticLog(
                    context = context,
                    source = "android.push_dispatcher",
                    message = "Delivered bank notification immediately from native listener.",
                    metadata = mapOf(
                        "fingerprint" to payload.optString("fingerprint"),
                    ),
                )
            } catch (error: Exception) {
                NotificationTrackingBridge.appendDiagnosticLog(
                    context = context,
                    source = "android.push_dispatcher",
                    message = "Immediate native push failed. Worker retry remains queued.",
                    level = "error",
                    metadata = mapOf(
                        "fingerprint" to payload.optString("fingerprint"),
                        "error" to (error.message ?: error.toString()),
                    ),
                )
            }
        }
    }

    fun sendPayload(context: Context, payload: JSONObject) {
        val prefs = context.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE)
        val baseUrl = prefs.getString(nativeBaseUrlKey, null)
        if (baseUrl.isNullOrBlank()) {
            throw IllegalStateException("Missing API base URL for /notifications/test call.")
        }

        val host = baseUrl.trim().trimEnd('/')
        val endpoint = if (host.startsWith("http://") || host.startsWith("https://")) {
            "$host/notifications/test"
        } else {
            "https://$host/notifications/test"
        }

        val cookieHeader = resolveCookieHeader(prefs, endpoint)
        val body = JSONObject().apply {
            put("title", buildPushTitle(payload))
            put("body", buildPushBody(payload))
            put(
                "data",
                JSONObject().apply {
                    put("fingerprint", payload.optString("fingerprint"))
                    put("packageName", payload.optString("packageName"))
                    put("bankKey", payload.optString("bankKey"))
                    put(
                        "amount",
                        if (payload.isNull("amount")) {
                            ""
                        } else {
                            payload.opt("amount").toString()
                        }
                    )
                    put("currency", payload.optString("currency", "USD"))
                    put("isIncome", payload.optBoolean("isIncome", true).toString())
                    put("message", payload.optString("message"))
                    put("title", payload.optString("title"))
                    put("receivedAt", payload.optLong("receivedAt").toString())
                    put("source", payload.optString("source", "native"))
                },
            )
        }

        val connection = (URL(endpoint).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            connectTimeout = 30_000
            readTimeout = 30_000
            doOutput = true
            setRequestProperty("Content-Type", "application/json")
            if (!cookieHeader.isNullOrBlank()) {
                setRequestProperty("Cookie", cookieHeader)
            }
        }

        try {
            OutputStreamWriter(connection.outputStream).use { writer ->
                writer.write(body.toString())
                writer.flush()
            }

            val responseCode = connection.responseCode
            if (responseCode !in 200..299) {
                val errorBody = connection.errorStream?.bufferedReader()
                    ?.use(BufferedReader::readText)
                throw IllegalStateException(
                    "Notify request failed: $responseCode ${errorBody.orEmpty()}",
                )
            }
        } finally {
            connection.disconnect()
        }
    }

    private fun buildPushTitle(payload: JSONObject): String {
        val originalTitle = payload.optString("title").trim()
        return if (payload.optBoolean("isIncome", true)) {
            "Income received"
        } else if (originalTitle.isNotBlank()) {
            originalTitle
        } else {
            "Expense recorded"
        }
    }

    private fun buildPushBody(payload: JSONObject): String {
        val amount = payload.optDouble("amount")
        val hasAmount = !payload.isNull("amount") && !amount.isNaN()
        if (!hasAmount) {
            return payload.optString("message").ifBlank {
                "Bank notification detected."
            }
        }

        val bankLabel = when (payload.optString("bankKey")) {
            "aba" -> "ABA Bank"
            "chip_mong" -> "Chip Mong Bank"
            "acleda" -> "ACLEDA Bank"
            else -> payload.optString("packageName").ifBlank { "Bank notification" }
        }
        val currency = payload.optString("currency", "USD")
        val amountLabel = if (currency == "KHR") {
            "KHR ${DecimalFormat("#,###").format(amount)}"
        } else {
            val format = if (amount % 1.0 == 0.0) DecimalFormat("#,###") else DecimalFormat("#,##0.00")
            "$ ${format.format(amount)}"
        }
        return "$bankLabel • $amountLabel"
    }

    private fun resolveCookieHeader(
        prefs: android.content.SharedPreferences,
        endpoint: String,
    ): String? {
        val rawCookies = prefs.getString(cookiePrefsKey, null) ?: return null
        val cookiesJson = JSONObject(rawCookies)
        val host = URL(endpoint).host
        val domainCookies = cookiesJson.optJSONObject(host) ?: return null
        val names = domainCookies.names() ?: return null
        val pairs = buildList {
            for (index in 0 until names.length()) {
                val name = names.optString(index)
                if (name.isBlank()) continue
                val value = domainCookies.optString(name)
                add("$name=$value")
            }
        }
        return pairs.takeIf { it.isNotEmpty() }?.joinToString("; ")
    }
}
