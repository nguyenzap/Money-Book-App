package com.nguyenzap.moneybook.autotrack

import android.app.Notification
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.util.concurrent.Executors

/**
 * Nghe thông báo của các app ngân hàng đã chọn.
 *
 * Không phải dịch vụ chạy liên tục: hệ thống tự gắn và chỉ gọi vào khi có
 * thông báo mới. Không foreground, không wakelock, không khởi động Flutter.
 *
 * Việc duy nhất ở đây là lọc theo gói và chép chữ vào [AutoTrackInbox]. Đọc
 * thành giao dịch là việc của Dart, lúc app mở.
 */
class AutoTrackListenerService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        // Dòng đầu tiên: app không theo dõi thì thôi, chưa đọc gì cả.
        if (!WatchedPackages.contains(this, sbn.packageName)) return

        val n = sbn.notification ?: return
        // Thông báo tóm tắt của một nhóm lặp lại nội dung các tin con.
        if (n.flags and Notification.FLAG_GROUP_SUMMARY != 0) return

        val extras = n.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
            ?: extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
                ?.joinToString("\n") { it.toString() }
            ?: extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            ?: ""
        if (text.isBlank()) return

        val pkg = sbn.packageName
        val postedAt = sbn.postTime
        io.execute {
            AutoTrackInbox.get(this).insert(pkg, title, text, postedAt)
            mainHandler.post { onNewItem?.invoke() }
        }
    }

    companion object {
        /** Một luồng nền duy nhất: ghi tuần tự, không chặn luồng chính. */
        private val io = Executors.newSingleThreadExecutor()
        private val mainHandler = Handler(Looper.getMainLooper())

        /** Đặt bởi MainActivity khi app đang mở, để Dart lấy tin ngay. */
        @Volatile
        var onNewItem: (() -> Unit)? = null
    }
}
