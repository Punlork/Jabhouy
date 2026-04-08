package com.pl.shop.management

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
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
}
