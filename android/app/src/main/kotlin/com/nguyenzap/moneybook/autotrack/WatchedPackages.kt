package com.nguyenzap.moneybook.autotrack

import android.content.Context
import android.content.SharedPreferences

/**
 * Các gói Android mà dịch vụ nghe thông báo được phép đọc.
 *
 * Nguồn sự thật nằm ở phía Dart (bảng tracked_apps); đây chỉ là bản sao để
 * dịch vụ lọc được ngay cả khi Flutter không chạy. Dart gửi lại toàn bộ danh
 * sách mỗi lần đổi và mỗi lần mở app.
 *
 * Giữ một bản trong bộ nhớ để mỗi thông báo chỉ tốn một phép tra Set.
 */
object WatchedPackages {
    private const val PREFS = "autotrack"
    private const val KEY = "watched_packages"

    @Volatile
    private var cache: Set<String>? = null

    fun contains(context: Context, packageName: String): Boolean =
        load(context).contains(packageName)

    fun set(context: Context, packages: Collection<String>) {
        val copy = packages.toSet()
        prefs(context).edit().putStringSet(KEY, copy).apply()
        cache = copy
    }

    private fun load(context: Context): Set<String> {
        cache?.let { return it }
        // Bản trả về của getStringSet không được sửa, nên sao ra.
        val loaded = prefs(context).getStringSet(KEY, emptySet())?.toSet() ?: emptySet()
        cache = loaded
        return loaded
    }

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
