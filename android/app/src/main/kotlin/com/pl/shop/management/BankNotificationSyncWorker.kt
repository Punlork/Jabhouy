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
import org.json.JSONObject
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

        if (NotificationTrackingBridge.hasActiveFlutterListener()) {
            NotificationTrackingBridge.appendDiagnosticLog(
                context = applicationContext,
                source = "android.sync_worker",
                message = "Skipping background notification sync because Flutter is actively handling notification events.",
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
                BankNotificationPushDispatcher.sendPayload(applicationContext, payload)
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

    companion object {
        private const val uniqueWorkName = "bank-notification-sync"
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
