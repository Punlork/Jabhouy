package com.pl.shop.management

import android.content.Context
import android.util.Log
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.text.DecimalFormat
import java.util.concurrent.TimeUnit

class BankNotificationSyncWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : Worker(appContext, workerParams) {
    override fun doWork(): Result {
        if (!NotificationTrackingBridge.isMainDevice(applicationContext)) {
            NotificationTrackingBridge.appendDiagnosticLog(
                context = applicationContext,
                source = "android.sync_worker",
                message = "Skipping background notification sync because this device is not the main device.",
            )
            return Result.success()
        }

        val pending = NotificationTrackingBridge.pendingUploads(applicationContext)
        if (pending.isEmpty()) {
            return Result.success()
        }

        val uploadedFingerprints = mutableListOf<String>()
        return try {
            for (payload in pending) {
                notifyBackend(payload)
                payload.optString("fingerprint")
                    .takeIf { it.isNotBlank() }
                    ?.let(uploadedFingerprints::add)
            }
            NotificationTrackingBridge.markUploaded(applicationContext, uploadedFingerprints)
            NotificationTrackingBridge.appendDiagnosticLog(
                context = applicationContext,
                source = "android.sync_worker",
                message = "Delivered pending bank notifications through backend test endpoint.",
                metadata = mapOf(
                    "count" to uploadedFingerprints.size,
                ),
            )
            Result.success()
        } catch (error: Exception) {
            NotificationTrackingBridge.markUploaded(applicationContext, uploadedFingerprints)
            Log.e(logTag, "Failed to upload bank notifications.", error)
            NotificationTrackingBridge.appendDiagnosticLog(
                context = applicationContext,
                source = "android.sync_worker",
                message = "Background notification sync failed.",
                level = "error",
                metadata = mapOf(
                    "error" to (error.message ?: error.toString()),
                ),
            )
            Result.retry()
        }
    }

    private fun notifyBackend(payload: JSONObject) {
        val prefs = applicationContext.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE)
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
                }
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
                val errorBody = connection.errorStream?.bufferedReader()?.use(BufferedReader::readText)
                throw IllegalStateException("Notify request failed: $responseCode ${errorBody.orEmpty()}")
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
        endpoint: String
    ): String? {
        val rawCookies = prefs.getString(cookiePrefsKey, null) ?: return null
        val cookiesJson = JSONObject(rawCookies)
        val host = URL(endpoint).host
        val domainCookies = cookiesJson.optJSONObject(host) ?: return null
        val names = JSONArray(domainCookies.names() ?: return null)
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

    companion object {
        private const val cookiePrefsKey = "flutter.cookies"
        private const val nativeBaseUrlKey = "flutter.income_sync_api_base_url"
        private const val uniqueWorkName = "bank-notification-sync"
        private const val sharedPrefsName = "FlutterSharedPreferences"
        private const val logTag = "BankNotificationSync"

        fun enqueue(context: Context) {
            val request = OneTimeWorkRequestBuilder<BankNotificationSyncWorker>()
                .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
                .setConstraints(
                    Constraints.Builder()
                        .setRequiredNetworkType(NetworkType.CONNECTED)
                        .build()
                )
                .setBackoffCriteria(
                    BackoffPolicy.EXPONENTIAL,
                    10,
                    TimeUnit.SECONDS
                )
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                uniqueWorkName,
                ExistingWorkPolicy.APPEND_OR_REPLACE,
                request
            )
        }
    }
}
