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
        private val supportedPackages = setOf(
            "com.paygo24.ibank",
            "com.chipmongbank.mobileappproduction",
            "com.domain.acledabankqr",
        )

        private val supportedBankMentions = listOf(
            "aba",
            "chip mong",
            "chipmong",
            "acleda",
        )

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
            if (isSupportedPackage(packageName)) {
                return true
            }

            val normalizedText = buildString {
                append(title.orEmpty())
                if (messageParts.isNotEmpty()) {
                    append(' ')
                    append(messageParts.joinToString(" "))
                }
            }.lowercase()

            if (looksLikeSupportedBankText(normalizedText)) {
                return true
            }

            return false
        }

        private fun isSupportedPackage(packageName: String): Boolean {
            return supportedPackages.contains(packageName.lowercase())
        }

        private fun looksLikeSupportedBankText(normalizedText: String): Boolean {
            if (normalizedText.isBlank()) return false

            return supportedBankMentions.any(normalizedText::contains)
        }

        private fun isRedactedPlaceholder(value: String): Boolean {
            val normalized = value.trim().lowercase()
            return normalized == "sensitive notification content hidden" ||
                normalized == "notification content hidden" ||
                normalized == "content hidden"
        }
    }
}
