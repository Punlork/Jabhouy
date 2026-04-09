package com.pl.shop.management

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.util.Log
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject

object NotificationTrackingBridge {
    private const val prefsName = "notification_tracking_bridge"
    private const val pendingKey = "flutter.pending_notifications"
    private const val uploadedKey = "flutter.uploaded_notification_fingerprints"
    private const val diagnosticsKey = "flutter.notification_diagnostics_logs"
    private const val scopeIdKey = "flutter.income_sync_scope_id"
    private const val deviceRoleKey = "flutter.deviceRole"
    private const val sharedPrefsName = "FlutterSharedPreferences"
    private const val maxDiagnosticEntries = 250
    private const val logTag = "NotificationTracking"

    private val lock = Any()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var logSink: EventChannel.EventSink? = null
    @Volatile
    private var isFlutterAppForeground: Boolean = false

    fun attachEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun attachLogSink(sink: EventChannel.EventSink?) {
        logSink = sink
    }

    fun setFlutterAppForeground(isForeground: Boolean) {
        isFlutterAppForeground = isForeground
    }

    fun hasActiveFlutterListener(): Boolean {
        return eventSink != null && isFlutterAppForeground
    }

    fun isNotificationAccessEnabled(context: Context): Boolean {
        val enabledListeners = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        val expectedComponent = ComponentName(
            context,
            BankNotificationListenerService::class.java,
        )
        return enabledListeners
            .split(':')
            .mapNotNull(ComponentName::unflattenFromString)
            .any { component ->
                component == expectedComponent
            }
    }

    fun openNotificationAccessSettings(context: Context) {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    fun requestNotificationListenerRebindIfNeeded(context: Context) {
        if (!isNotificationAccessEnabled(context)) {
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            NotificationListenerService.requestRebind(
                ComponentName(context, BankNotificationListenerService::class.java),
            )
        }
    }

    fun drainPendingNotifications(context: Context): List<Map<String, Any?>> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE)
            val raw = prefs.getString(pendingKey, null)
                ?: context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                    .getString("pending_notifications", "[]")
                ?: "[]"
            prefs.edit().remove(pendingKey).apply()
            prefs.edit().remove(uploadedKey).apply()
            context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                .edit()
                .remove("pending_notifications")
                .apply()
            return jsonArrayToMaps(JSONArray(raw))
        }
    }

    fun pushDemoNotifications(context: Context) {
        appendDiagnosticLog(
            context = context,
            source = "android.bridge",
            message = "Queueing demo notifications."
        )

        val now = System.currentTimeMillis()
        val demos = listOf(
            buildPayload(
                packageName = "com.paygo24.ibank",
                title = "Money received",
                message = "ABA: You received USD 245.00 from customer payment.",
                receivedAt = now,
                source = "demo"
            ),
            buildPayload(
                packageName = "com.chipmongbank.mobileappproduction",
                title = "Incoming transfer",
                message = "Chip Mong Bank incoming transfer USD 180.50 into your account.",
                receivedAt = now - 2 * 60 * 60 * 1000,
                source = "demo"
            ),
            buildPayload(
                packageName = "com.domain.acledabankqr",
                title = "Transfer out",
                message = "ACLEDA transfer out KHR 40,000 from account.",
                receivedAt = now - 24 * 60 * 60 * 1000,
                source = "demo"
            )
        )

        demos.forEach { queueNotification(context, it) }
    }

    fun buildPayload(
        packageName: String,
        title: String?,
        message: String,
        receivedAt: Long,
        source: String = "native"
    ): JSONObject {
        val normalizedText = listOfNotNull(title, message).joinToString(" ").lowercase()
        val bankKey = detectBank(packageName, normalizedText)
        val currency = detectCurrency(normalizedText)
        val amount = parseAmount(normalizedText)
        val isIncome = detectIncome(normalizedText)
        val payload = JSONObject()
        payload.put("fingerprint", listOf(packageName, title ?: "", message, receivedAt).joinToString("|"))
        payload.put("packageName", packageName)
        payload.put("bankKey", bankKey)
        payload.put("title", title)
        payload.put("message", message)
        payload.put("amount", amount)
        payload.put("currency", currency)
        payload.put("isIncome", isIncome)
        payload.put("receivedAt", receivedAt)
        payload.put("source", source)
        payload.put("rawPayload", payload.toString())
        return payload
    }

    fun queueNotification(context: Context, payload: JSONObject) {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE)
            val raw = prefs.getString(pendingKey, "[]") ?: "[]"
            val array = JSONArray(raw)
            array.put(payload)
            prefs.edit().putString(pendingKey, array.toString()).apply()
        }

        appendDiagnosticLog(
            context = context,
            source = "android.bridge",
            message = "Queued notification payload for Flutter and background sync.",
            metadata = mapOf(
                "fingerprint" to payload.optString("fingerprint"),
                "packageName" to payload.optString("packageName"),
                "bankKey" to payload.optString("bankKey"),
                "source" to payload.optString("source", "native"),
            )
        )

        val event = jsonToMap(payload)
        mainHandler.post {
            eventSink?.success(event)
        }
        BankNotificationSyncWorker.enqueue(context)
    }

    fun pendingUploads(context: Context): List<JSONObject> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE)
            val pending = JSONArray(prefs.getString(pendingKey, "[]") ?: "[]")
            val uploaded = prefs.getStringSet(uploadedKey, emptySet()) ?: emptySet()
            return buildList {
                for (index in 0 until pending.length()) {
                    val item = pending.optJSONObject(index) ?: continue
                    val fingerprint = item.optString("fingerprint")
                    if (fingerprint.isNotBlank() && uploaded.contains(fingerprint)) continue
                    add(item)
                }
            }
        }
    }

    fun markUploaded(context: Context, fingerprints: Collection<String>) {
        if (fingerprints.isEmpty()) return
        synchronized(lock) {
            val prefs = context.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE)
            val current = prefs.getStringSet(uploadedKey, emptySet())?.toMutableSet() ?: mutableSetOf()
            current.addAll(fingerprints)
            val pending = JSONArray(prefs.getString(pendingKey, "[]") ?: "[]")
            val retained = JSONArray()
            for (index in 0 until pending.length()) {
                val item = pending.optJSONObject(index) ?: continue
                val fingerprint = item.optString("fingerprint")
                if (fingerprint.isNotBlank() && fingerprints.contains(fingerprint)) {
                    continue
                }
                retained.put(item)
            }
            prefs.edit()
                .putStringSet(uploadedKey, current)
                .putString(pendingKey, retained.toString())
                .apply()
        }
    }

    fun readScopeId(context: Context): String? {
        return context.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE)
            .getString(scopeIdKey, null)
    }

    fun isMainDevice(context: Context): Boolean {
        val role = context.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE)
            .getString(deviceRoleKey, "sub")
        return role == "main"
    }

    fun readDiagnosticsLogs(context: Context): List<Map<String, Any?>> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE)
            val raw = prefs.getString(diagnosticsKey, "[]") ?: "[]"
            return jsonArrayToMaps(JSONArray(raw))
        }
    }

    fun clearDiagnosticsLogs(context: Context) {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE)
            prefs.edit().remove(diagnosticsKey).apply()
        }
    }

    fun appendDiagnosticLog(
        context: Context,
        source: String,
        message: String,
        level: String = "info",
        metadata: Map<String, Any?>? = null,
    ) {
        val entry = JSONObject().apply {
            put("timestamp", System.currentTimeMillis())
            put("source", source)
            put("level", level)
            put("message", message)
            put("metadata", metadata?.let(::mapToJsonObject) ?: JSONObject())
        }

        synchronized(lock) {
            val prefs = context.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE)
            val raw = prefs.getString(diagnosticsKey, "[]") ?: "[]"
            val existing = JSONArray(raw)
            existing.put(entry)

            val trimmed = JSONArray()
            val startIndex = maxOf(0, existing.length() - maxDiagnosticEntries)
            for (index in startIndex until existing.length()) {
                trimmed.put(existing.get(index))
            }

            prefs.edit().putString(diagnosticsKey, trimmed.toString()).apply()
        }

        when (level.lowercase()) {
            "error" -> Log.e(logTag, "[$source] $message ${metadata.orEmpty()}")
            "warning" -> Log.w(logTag, "[$source] $message ${metadata.orEmpty()}")
            else -> Log.d(logTag, "[$source] $message ${metadata.orEmpty()}")
        }

        val logEvent = jsonToMap(entry)
        mainHandler.post {
            logSink?.success(logEvent)
        }
    }

    private fun detectBank(packageName: String, normalizedText: String): String {
        return when (packageName) {
            "com.paygo24.ibank" -> "aba"
            "com.chipmongbank.mobileappproduction" -> "chip_mong"
            "com.domain.acledabankqr" -> "acleda"
            else -> when {
                normalizedText.contains("acleda") -> "acleda"
                normalizedText.contains("chip mong") -> "chip_mong"
                normalizedText.contains("aba") -> "aba"
                else -> "unknown"
            }
        }
    }

    private fun detectCurrency(normalizedText: String): String {
        return when {
            normalizedText.contains("khr") || normalizedText.contains("៛") -> "KHR"
            else -> "USD"
        }
    }

    private fun detectIncome(normalizedText: String): Boolean {
        val incomeKeywords = listOf(
            "received",
            "incoming",
            "credit",
            "credited",
            "deposit",
            "cash in",
            "payment received",
            "received from",
            "transfer in",
            "incoming transfer",
            "បានទទួល",
            "ទទួលបាន",
            "ផ្ទេរចូល",
            "វេរចូល",
            "ប្រាក់ចូល",
            "ដាក់ប្រាក់",
            "បញ្ចូលប្រាក់",
            "ទទួល",
        )
        val expenseKeywords = listOf(
            "transfer out",
            "debited",
            "debit",
            "sent",
            "paid",
            "withdraw",
            "payment to",
            "transfer to",
            "cash out",
            "outgoing transfer",
            "ផ្ទេរចេញ",
            "វេរចេញ",
            "ប្រាក់ចេញ",
            "បានផ្ទេរ",
            "ទូទាត់",
            "បង់ប្រាក់",
            "ដកប្រាក់"
        )

        if (expenseKeywords.any { normalizedText.contains(it) }) return false
        if (incomeKeywords.any { normalizedText.contains(it) }) return true
        return !Regex("""(?:usd|us\$|\$|khr|៛)\s*[-–]""").containsMatchIn(normalizedText)
    }

    private fun parseAmount(normalizedText: String): Double? {
        val currencyFirst = Regex("""(?:usd|us\$|\$|khr|៛)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)""")
        val match = currencyFirst.find(normalizedText)
            ?: Regex("""([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)""").find(normalizedText)
        val value = match?.groupValues?.getOrNull(1) ?: return null
        return value.replace(",", "").toDoubleOrNull()
    }

    private fun jsonArrayToMaps(array: JSONArray): List<Map<String, Any?>> {
        return buildList {
            for (index in 0 until array.length()) {
                val item = array.optJSONObject(index) ?: continue
                add(jsonToMap(item))
            }
        }
    }

    private fun jsonToMap(json: JSONObject): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        val iterator = json.keys()
        while (iterator.hasNext()) {
            val key = iterator.next()
            val value = json.get(key)
            map[key] = when {
                value == JSONObject.NULL -> null
                value is JSONObject -> jsonToMap(value)
                value is JSONArray -> (0 until value.length()).map { index ->
                    val item = value.get(index)
                    when (item) {
                        is JSONObject -> jsonToMap(item)
                        JSONObject.NULL -> null
                        else -> item
                    }
                }
                else -> value
            }
        }
        return map
    }

    private fun mapToJsonObject(map: Map<String, Any?>): JSONObject {
        val json = JSONObject()
        for ((key, value) in map) {
            json.put(key, value.toJsonValue())
        }
        return json
    }

    private fun Any?.toJsonValue(): Any? {
        return when (this) {
            null -> JSONObject.NULL
            is JSONObject, is JSONArray, is String, is Boolean, is Int, is Long, is Double -> this
            is Float -> this.toDouble()
            is Number -> this.toDouble()
            is Map<*, *> -> JSONObject().apply {
                this@toJsonValue.forEach { (key, value) ->
                    if (key != null) {
                        put(key.toString(), value.toJsonValue())
                    }
                }
            }
            is Iterable<*> -> JSONArray().apply {
                this@toJsonValue.forEach { item ->
                    put(item.toJsonValue())
                }
            }
            is Array<*> -> JSONArray().apply {
                this@toJsonValue.forEach { item ->
                    put(item.toJsonValue())
                }
            }
            else -> this.toString()
        }
    }
}
