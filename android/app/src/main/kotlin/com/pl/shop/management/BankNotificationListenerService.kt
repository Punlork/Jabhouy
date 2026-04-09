package com.pl.shop.management

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class BankNotificationListenerService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName ?: return
        if (packageName !in supportedPackages) {
            if (looksRelevant(packageName)) {
                NotificationTrackingBridge.appendDiagnosticLog(
                    context = applicationContext,
                    source = "android.listener",
                    message = "Ignored notification from unsupported package.",
                    level = "warning",
                    metadata = mapOf(
                        "packageName" to packageName,
                    ),
                )
            }
            return
        }

        val extras = sbn.notification.extras
        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val messageParts = buildList {
            add(extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString())
            add(extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString())
            add(extras?.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString())
            add(extras?.getCharSequence(Notification.EXTRA_SUMMARY_TEXT)?.toString())
            add(sbn.notification.tickerText?.toString())
            val textLines = extras?.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
            textLines?.forEach { add(it?.toString()) }
        }.filterNotNull()
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .distinct()
        val visibleMessageParts = messageParts.filterNot(::isRedactedPlaceholder)

        val message = visibleMessageParts.joinToString(" ").ifBlank {
            if (messageParts.isNotEmpty()) {
                NotificationTrackingBridge.appendDiagnosticLog(
                    context = applicationContext,
                    source = "android.listener",
                    message = "Ignored redacted bank notification because Android exposed only hidden-content placeholders.",
                    level = "warning",
                    metadata = mapOf(
                        "packageName" to packageName,
                        "title" to (title ?: ""),
                        "messageParts" to messageParts,
                        "visibility" to sbn.notification.visibility,
                        "hasPublicVersion" to (sbn.notification.publicVersion != null),
                    ),
                )
                return
            }
            NotificationTrackingBridge.appendDiagnosticLog(
                context = applicationContext,
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
            context = applicationContext,
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
            receivedAt = sbn.postTime,
        )
        NotificationTrackingBridge.queueNotification(applicationContext, payload)
    }

    companion object {
        private val supportedPackages = setOf(
            "com.paygo24.ibank",
            "com.chipmongbank.mobileappproduction",
            "com.domain.acledabankqr",
        )

        private fun looksRelevant(packageName: String): Boolean {
            val normalized = packageName.lowercase()
            return normalized.contains("aba") ||
                normalized.contains("chip") ||
                normalized.contains("mong") ||
                normalized.contains("bank") ||
                normalized.contains("acleda")
        }

        private fun isRedactedPlaceholder(value: String): Boolean {
            val normalized = value.trim().lowercase()
            return normalized == "sensitive notification content hidden" ||
                normalized == "notification content hidden" ||
                normalized == "content hidden"
        }
    }
}
