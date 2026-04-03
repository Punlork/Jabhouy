package com.pl.shop.management

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class BankNotificationListenerService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName ?: return
        if (packageName !in supportedPackages) return

        val extras = sbn.notification.extras
        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val messageParts = buildList {
            add(extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString())
            add(extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString())
            add(extras?.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString())
            val textLines = extras?.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
            textLines?.forEach { add(it?.toString()) }
        }.filterNotNull().map { it.trim() }.filter { it.isNotEmpty() }.distinct()

        val message = messageParts.joinToString("").ifBlank { return }
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
            "kh.com.acleda.acledamobile",
        )
    }
}
