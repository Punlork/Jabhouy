package com.pl.shop.management

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class BankNotificationListenerService : NotificationListenerService() {
    override fun onListenerConnected() {
        super.onListenerConnected()
        NotificationTrackingBridge.appendDiagnosticLog(
            context = applicationContext,
            source = "android.listener",
            message = "Notification listener connected.",
        )
    }

    override fun onListenerDisconnected() {
        NotificationTrackingBridge.appendDiagnosticLog(
            context = applicationContext,
            source = "android.listener",
            message = "Notification listener disconnected; requesting rebind.",
            level = "warning",
        )
        NotificationTrackingBridge.requestNotificationListenerRebindIfNeeded(applicationContext)
        super.onListenerDisconnected()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        handleNotification(
            context = applicationContext,
            packageName = sbn.packageName ?: return,
            title = sbn.notification.extras
                ?.getCharSequence(Notification.EXTRA_TITLE)
                ?.toString(),
            messageParts = buildList {
                val extras = sbn.notification.extras
                add(extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString())
                add(extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString())
                add(extras?.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString())
                add(extras?.getCharSequence(Notification.EXTRA_SUMMARY_TEXT)?.toString())
                add(sbn.notification.tickerText?.toString())
                val textLines = extras?.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
                textLines?.forEach { add(it?.toString()) }
            },
            receivedAt = sbn.postTime,
            visibility = sbn.notification.visibility,
            hasPublicVersion = sbn.notification.publicVersion != null,
        )
    }

    companion object {
        fun simulateNotificationPosted(
            context: android.content.Context,
            packageName: String,
            title: String?,
            messageParts: List<String>,
            receivedAt: Long,
        ) {
            handleNotification(
                context = context,
                packageName = packageName,
                title = title,
                messageParts = messageParts,
                receivedAt = receivedAt,
                visibility = null,
                hasPublicVersion = false,
            )
        }

        private fun handleNotification(
            context: android.content.Context,
            packageName: String,
            title: String?,
            messageParts: List<String?>,
            receivedAt: Long,
            visibility: Int?,
            hasPublicVersion: Boolean,
        ) {
            val normalizedMessageParts = messageParts.filterNotNull()
                .map { it.trim() }
                .filter { it.isNotEmpty() }
                .distinct()

            if (!shouldTrackNotification(packageName, title, normalizedMessageParts)) {
                return
            }

            val visibleMessageParts = normalizedMessageParts.filterNot(::isRedactedPlaceholder)

            val message = visibleMessageParts.joinToString(" ").ifBlank {
                if (normalizedMessageParts.isNotEmpty()) {
                    NotificationTrackingBridge.appendDiagnosticLog(
                        context = context,
                        source = "android.listener",
                        message = "Ignored redacted bank notification because Android exposed only hidden-content placeholders.",
                        level = "warning",
                        metadata = mapOf(
                            "packageName" to packageName,
                            "title" to (title ?: ""),
                            "messageParts" to normalizedMessageParts,
                            "visibility" to (visibility ?: "unknown"),
                            "hasPublicVersion" to hasPublicVersion,
                        ),
                    )
                    return
                }
                NotificationTrackingBridge.appendDiagnosticLog(
                    context = context,
                    source = "android.listener",
                    message = "Ignored notification because the listener could not extract message text.",
                    level = "warning",
                    metadata = mapOf(
                        "packageName" to packageName,
                        "title" to (title ?: ""),
                    ),
                )
                return
            }
            NotificationTrackingBridge.appendDiagnosticLog(
                context = context,
                source = "android.listener",
                message = "Captured supported bank notification.",
                metadata = mapOf(
                    "packageName" to packageName,
                    "title" to (title ?: ""),
                ),
            )
            val payload = NotificationTrackingBridge.buildPayload(
                packageName = packageName,
                title = title,
                message = message,
                receivedAt = receivedAt,
            )
            NotificationTrackingBridge.queueNotification(context, payload)
            BankNotificationPushDispatcher.dispatchImmediatelyIfFlutterInactive(
                context,
                payload,
            )
        }

        private fun shouldTrackNotification(
            packageName: String,
            title: String?,
            messageParts: List<String>,
        ): Boolean {
            if (looksRelevantPackage(packageName)) {
                return true
            }

            val normalizedText = buildString {
                append(title.orEmpty())
                if (messageParts.isNotEmpty()) {
                    append(' ')
                    append(messageParts.joinToString(" "))
                }
            }.lowercase()

            if (looksRelevantText(normalizedText)) {
                return true
            }

            return false
        }

        private fun looksRelevantPackage(packageName: String): Boolean {
            val normalized = packageName.lowercase()
            return normalized.contains("aba") ||
                normalized.contains("chip") ||
                normalized.contains("mong") ||
                normalized.contains("bank") ||
                normalized.contains("acleda") ||
                normalized.contains("wing") ||
                normalized.contains("wallet") ||
                normalized.contains("pay")
        }

        private fun looksRelevantText(normalizedText: String): Boolean {
            if (normalizedText.isBlank()) return false

            val financialKeywords = listOf(
                "received",
                "incoming",
                "credited",
                "credit",
                "deposit",
                "transfer",
                "payment",
                "debit",
                "debited",
                "withdraw",
                "cash in",
                "cash out",
                "received from",
                "transfer in",
                "transfer out",
                "bank",
                "account",
                "wallet",
                "khqr",
                "usd",
                "khr",
                "៛",
                "បានទទួល",
                "ទទួលបាន",
                "ផ្ទេរចូល",
                "ផ្ទេរចេញ",
                "វេរចូល",
                "វេរចេញ",
                "ប្រាក់ចូល",
                "ប្រាក់ចេញ",
                "ដាក់ប្រាក់",
                "ដកប្រាក់",
                "បញ្ចូលប្រាក់",
                "ទូទាត់",
                "បង់ប្រាក់",
            )

            return financialKeywords.any(normalizedText::contains)
        }

        private fun isRedactedPlaceholder(value: String): Boolean {
            val normalized = value.trim().lowercase()
            return normalized == "sensitive notification content hidden" ||
                normalized == "notification content hidden" ||
                normalized == "content hidden"
        }
    }
}
