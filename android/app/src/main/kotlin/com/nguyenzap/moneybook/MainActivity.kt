package com.nguyenzap.moneybook

import android.content.ComponentName
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.service.notification.NotificationListenerService
import com.nguyenzap.moneybook.autotrack.AutoTrackInbox
import com.nguyenzap.moneybook.autotrack.AutoTrackListenerService
import com.nguyenzap.moneybook.autotrack.WatchedPackages
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "moneybook/autotrack").setMethodCallHandler { call, result ->
            when (call.method) {
                "readInbox" -> background(result) {
                    AutoTrackInbox.get(this).read().map {
                        mapOf(
                            "id" to it.id,
                            "packageName" to it.packageName,
                            "title" to it.title,
                            "text" to it.text,
                            "postedAt" to it.postedAt,
                        )
                    }
                }
                "ackInbox" -> {
                    val maxId = (call.argument<Number>("maxId") ?: 0).toLong()
                    background(result) { AutoTrackInbox.get(this).ack(maxId); null }
                }
                "setWatchedPackages" -> {
                    WatchedPackages.set(this, call.argument<List<String>>("packages") ?: emptyList())
                    result.success(null)
                }
                "isListenerEnabled" -> result.success(isListenerEnabled())
                "openListenerSettings" -> {
                    startActivity(
                        Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                    result.success(null)
                }
                "requestRebind" -> {
                    // HyperOS hay ngắt dịch vụ; xin hệ thống gắn lại. Vô hại nếu
                    // dịch vụ đang chạy.
                    if (isListenerEnabled()) {
                        NotificationListenerService.requestRebind(listenerComponent())
                    }
                    result.success(null)
                }
                "listLaunchableApps" -> background(result) { launchableApps() }
                "isPackageInstalled" -> {
                    val pkg = call.argument<String>("packageName") ?: ""
                    result.success(
                        try {
                            packageManager.getPackageInfo(pkg, 0); true
                        } catch (e: Exception) {
                            false
                        },
                    )
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "moneybook/autotrack/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    AutoTrackListenerService.onNewItem = { events.success(null) }
                }

                override fun onCancel(arguments: Any?) {
                    AutoTrackListenerService.onNewItem = null
                }
            },
        )
    }

    override fun onDestroy() {
        AutoTrackListenerService.onNewItem = null
        super.onDestroy()
    }

    private fun listenerComponent() =
        ComponentName(this, AutoTrackListenerService::class.java)

    private fun isListenerEnabled(): Boolean {
        val enabled = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
            ?: return false
        val me = listenerComponent()
        return enabled.split(':').any { ComponentName.unflattenFromString(it) == me }
    }

    /** App có biểu tượng ngoài màn hình chính, để chọn khi "ghi mẫu". */
    private fun launchableApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(intent, 0)
            .map { it.activityInfo.applicationInfo }
            .distinctBy { it.packageName }
            .filter { it.packageName != packageName }
            .map { info ->
                mapOf(
                    "packageName" to info.packageName,
                    "label" to pm.getApplicationLabel(info).toString(),
                    "icon" to try {
                        png(pm.getApplicationIcon(info))
                    } catch (e: Exception) {
                        null
                    },
                )
            }
            .sortedBy { (it["label"] as String).lowercase() }
    }

    private fun png(drawable: Drawable, size: Int = 96): ByteArray {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(canvas)
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        bitmap.recycle()
        return out.toByteArray()
    }

    /** Chạy ngoài luồng chính rồi trả kết quả về luồng chính. */
    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("autotrack", e.message, null) }
            }
        }
    }
}
