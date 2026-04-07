package com.pl.shop.management

import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject

object NotificationTrackingBridge {
    private const val prefsName = "notification_tracking_bridge"
    private const val pendingKey = "pending_notifications"
    private val lock = Any()
    private var eventSink: EventChannel.EventSink? = null

    fun attachEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun isNotificationAccessEnabled(context: Context): Boolean {
        val enabledListeners = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        return enabledListeners.contains(context.packageName)
    }

    fun openNotificationAccessSettings(context: Context) {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    fun drainPendingNotifications(context: Context): List<Map<String, Any?>> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            val raw = prefs.getString(pendingKey, "[]") ?: "[]"
            prefs.edit().remove(pendingKey).apply()
            return jsonArrayToMaps(JSONArray(raw))
        }
    }

    fun pushDemoNotifications(context: Context) {
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
                packageName = "kh.com.acleda.acledamobile",
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
            val prefs = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            val raw = prefs.getString(pendingKey, "[]") ?: "[]"
            val array = JSONArray(raw)
            array.put(payload)
            prefs.edit().putString(pendingKey, array.toString()).apply()
        }
        eventSink?.success(jsonToMap(payload))
    }

    private fun detectBank(packageName: String, normalizedText: String): String {
        return when {
            packageName == "com.paygo24.ibank" || normalizedText.contains("aba") -> "aba"
            packageName == "com.chipmongbank.mobileappproduction" || normalizedText.contains("chip mong") -> "chip_mong"
            packageName == "kh.com.acleda.acledamobile" || normalizedText.contains("acleda") -> "acleda"
            else -> "unknown"
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
            "បញ្ចូលប្រាក់"
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
            map[key] = if (value == JSONObject.NULL) null else value
        }
        return map
    }
}
