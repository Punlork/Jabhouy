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
import com.google.android.gms.tasks.Tasks
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit

class BankNotificationSyncWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : Worker(appContext, workerParams) {
    override fun doWork(): Result {
        if (!NotificationTrackingBridge.isMainDevice(applicationContext)) {
            return Result.success()
        }

        val scopeId = NotificationTrackingBridge.readScopeId(applicationContext)
        if (scopeId.isNullOrBlank()) {
            return Result.success()
        }

        val firebaseApp = ensureFirebaseApp() ?: return Result.failure()
        val firestore = FirebaseFirestore.getInstance(firebaseApp)
        val pending = NotificationTrackingBridge.pendingUploads(applicationContext)
        if (pending.isEmpty()) {
            return Result.success()
        }

        val uploadedFingerprints = mutableListOf<String>()
        return try {
            for (payload in pending) {
                uploadPayload(firestore, scopeId, payload)
                notifyBackend(scopeId, payload)
                payload.optString("fingerprint")
                    .takeIf { it.isNotBlank() }
                    ?.let(uploadedFingerprints::add)
            }
            NotificationTrackingBridge.markUploaded(applicationContext, uploadedFingerprints)
            Result.success()
        } catch (error: Exception) {
            NotificationTrackingBridge.markUploaded(applicationContext, uploadedFingerprints)
            Log.e(logTag, "Failed to upload bank notifications.", error)
            Result.retry()
        }
    }

    private fun ensureFirebaseApp(): FirebaseApp? {
        FirebaseApp.getApps(applicationContext).firstOrNull()?.let { return it }
        FirebaseApp.initializeApp(applicationContext)?.let { return it }

        val prefs = applicationContext.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE)
        val apiKey = prefs.getString("flutter.income_sync_firebase_api_key", null)
        val appId = prefs.getString("flutter.income_sync_firebase_app_id_android", null)
        val projectId = prefs.getString("flutter.income_sync_firebase_project_id", null)
        val senderId = prefs.getString("flutter.income_sync_firebase_messaging_sender_id", null)
        val storageBucket = prefs.getString("flutter.income_sync_firebase_storage_bucket", null)

        if (apiKey.isNullOrBlank() || appId.isNullOrBlank() || projectId.isNullOrBlank() || senderId.isNullOrBlank()) {
            Log.w(logTag, "Missing Firebase config for native background sync.")
            return null
        }

        val optionsBuilder = FirebaseOptions.Builder()
            .setApiKey(apiKey)
            .setApplicationId(appId)
            .setProjectId(projectId)
            .setGcmSenderId(senderId)

        if (!storageBucket.isNullOrBlank()) {
            optionsBuilder.setStorageBucket(storageBucket)
        }

        return FirebaseApp.initializeApp(applicationContext, optionsBuilder.build(), nativeAppName)
    }

    private fun uploadPayload(
        firestore: FirebaseFirestore,
        scopeId: String,
        payload: JSONObject
    ) {
        val fingerprint = payload.optString("fingerprint")
        if (fingerprint.isBlank()) return

        val data = mutableMapOf<String, Any>(
            "fingerprint" to fingerprint,
            "packageName" to payload.optString("packageName"),
            "bankKey" to payload.optString("bankKey"),
            "message" to payload.optString("message"),
            "currency" to payload.optString("currency", "USD"),
            "isIncome" to payload.optBoolean("isIncome", true),
            "receivedAt" to payload.optLong("receivedAt"),
            "source" to payload.optString("source", "native"),
            "rawPayload" to payload.optString("rawPayload", payload.toString()),
            "syncedAt" to FieldValue.serverTimestamp(),
        )

        payload.optString("title")
            .takeIf { it.isNotBlank() }
            ?.let { data["title"] = it }

        if (!payload.isNull("amount")) {
            data["amount"] = payload.optDouble("amount")
        }

        Tasks.await(
            firestore.collection("income_sync_scopes")
                .document(scopeId)
                .collection("notifications")
                .document(fingerprint)
                .set(data, SetOptions.merge())
        )
    }

    private fun notifyBackend(scopeId: String, payload: JSONObject) {
        val prefs = applicationContext.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE)
        val baseUrl = prefs.getString(nativeBaseUrlKey, null)
        if (baseUrl.isNullOrBlank()) {
            Log.w(logTag, "Missing API base URL for /income/notify call.")
            return
        }

        val host = baseUrl.trim().trimEnd('/')
        val endpoint = if (host.startsWith("http://") || host.startsWith("https://")) {
            "$host/income/notify"
        } else {
            "https://$host/income/notify"
        }

        val cookieHeader = resolveCookieHeader(prefs, endpoint)
        val body = JSONObject().apply {
            put("scopeId", scopeId)
            put("fingerprint", payload.optString("fingerprint"))
            put("bankKey", payload.optString("bankKey"))
            put("amount", if (payload.isNull("amount")) JSONObject.NULL else payload.optDouble("amount"))
            put("currency", payload.optString("currency", "USD"))
            put("isIncome", payload.optBoolean("isIncome", true))
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
        private const val nativeAppName = "income-native-sync"
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
