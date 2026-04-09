package com.pl.shop.management

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    override fun onStart() {
        super.onStart()
        NotificationTrackingBridge.setFlutterAppForeground(true)
        NotificationTrackingBridge.requestNotificationListenerRebindIfNeeded(applicationContext)
    }

    override fun onStop() {
        NotificationTrackingBridge.setFlutterAppForeground(false)
        super.onStop()
    }

    override fun onDestroy() {
        NotificationTrackingBridge.setFlutterAppForeground(false)
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "jabhouy/notification_tracking/methods"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationAccessEnabled" -> {
                    result.success(NotificationTrackingBridge.isNotificationAccessEnabled(applicationContext))
                }
                "openNotificationAccessSettings" -> {
                    NotificationTrackingBridge.openNotificationAccessSettings(applicationContext)
                    result.success(null)
                }
                "drainPendingTrackedNotifications" -> {
                    result.success(NotificationTrackingBridge.drainPendingNotifications(applicationContext))
                }
                "pushDemoNotifications" -> {
                    NotificationTrackingBridge.pushDemoNotifications(applicationContext)
                    result.success(null)
                }
                "sendNativeTestPush" -> {
                    val payload = JSONObject()
                    val arguments = call.argument<Map<String, Any?>>("payload").orEmpty()
                    arguments.forEach { (key, value) ->
                        payload.put(key, value.toJsonValue())
                    }

                    Thread {
                        try {
                            BankNotificationPushDispatcher.sendPayload(applicationContext, payload)
                            NotificationTrackingBridge.appendDiagnosticLog(
                                context = applicationContext,
                                source = "android.push_dispatcher",
                                message = "Manual native push test succeeded.",
                                metadata = mapOf(
                                    "fingerprint" to payload.optString("fingerprint"),
                                ),
                            )
                            Handler(Looper.getMainLooper()).post {
                                result.success(true)
                            }
                        } catch (error: Exception) {
                            NotificationTrackingBridge.appendDiagnosticLog(
                                context = applicationContext,
                                source = "android.push_dispatcher",
                                message = "Manual native push test failed.",
                                level = "error",
                                metadata = mapOf(
                                    "fingerprint" to payload.optString("fingerprint"),
                                    "error" to (error.message ?: error.toString()),
                                ),
                            )
                            Handler(Looper.getMainLooper()).post {
                                result.error(
                                    "native_push_failed",
                                    error.message ?: error.toString(),
                                    null,
                                )
                            }
                        }
                    }.start()
                }
                "getDiagnosticsLogs" -> {
                    result.success(NotificationTrackingBridge.readDiagnosticsLogs(applicationContext))
                }
                "clearDiagnosticsLogs" -> {
                    NotificationTrackingBridge.clearDiagnosticsLogs(applicationContext)
                    result.success(null)
                }
                "appendDiagnosticsLog" -> {
                    val source = call.argument<String>("source").orEmpty()
                    val level = call.argument<String>("level") ?: "info"
                    val message = call.argument<String>("message").orEmpty()
                    val metadata = call.argument<Map<String, Any?>>("metadata")
                    NotificationTrackingBridge.appendDiagnosticLog(
                        context = applicationContext,
                        source = source,
                        level = level,
                        message = message,
                        metadata = metadata,
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "jabhouy/notification_tracking/events"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NotificationTrackingBridge.attachEventSink(events)
            }

            override fun onCancel(arguments: Any?) {
                NotificationTrackingBridge.attachEventSink(null)
            }
        })

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "jabhouy/notification_tracking/logs"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NotificationTrackingBridge.attachLogSink(events)
            }

            override fun onCancel(arguments: Any?) {
                NotificationTrackingBridge.attachLogSink(null)
            }
        })
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
