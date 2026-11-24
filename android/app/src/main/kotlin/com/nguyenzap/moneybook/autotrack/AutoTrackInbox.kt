package com.nguyenzap.moneybook.autotrack

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

/**
 * Hộp thư tạm phía Android: dịch vụ nghe thông báo ghi vào đây khi Flutter
 * không chạy, Dart lấy ra khi mở app.
 *
 * Lấy ra theo hai bước — [read] rồi [ack] — để nếu Dart chết giữa chừng thì
 * tin vẫn còn và được lấy lại lần sau. Bên Dart chống trùng bằng dedupe hash
 * nên lấy lại hai lần không sinh giao dịch kép.
 */
class AutoTrackInbox private constructor(context: Context) :
    SQLiteOpenHelper(context.applicationContext, "autotrack_inbox.db", null, 1) {

    data class Item(
        val id: Long,
        val packageName: String,
        val title: String,
        val text: String,
        val postedAt: Long,
    )

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            "CREATE TABLE inbox (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "package_name TEXT NOT NULL, " +
                "title TEXT NOT NULL, " +
                "text TEXT NOT NULL, " +
                "posted_at INTEGER NOT NULL)",
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {}

    fun insert(packageName: String, title: String, text: String, postedAt: Long) {
        val values = ContentValues().apply {
            put("package_name", packageName)
            put("title", title)
            put("text", text)
            put("posted_at", postedAt)
        }
        writableDatabase.insert("inbox", null, values)
    }

    fun read(limit: Int = 500): List<Item> {
        val out = ArrayList<Item>()
        readableDatabase.query(
            "inbox",
            arrayOf("id", "package_name", "title", "text", "posted_at"),
            null, null, null, null,
            "id ASC",
            limit.toString(),
        ).use { c ->
            while (c.moveToNext()) {
                out.add(Item(c.getLong(0), c.getString(1), c.getString(2), c.getString(3), c.getLong(4)))
            }
        }
        return out
    }

    /** Xoá mọi tin có id <= [maxId] — tức là những tin Dart đã lưu xong. */
    fun ack(maxId: Long) {
        writableDatabase.delete("inbox", "id <= ?", arrayOf(maxId.toString()))
    }

    companion object {
        @Volatile
        private var instance: AutoTrackInbox? = null

        fun get(context: Context): AutoTrackInbox =
            instance ?: synchronized(this) {
                instance ?: AutoTrackInbox(context).also { instance = it }
            }
    }
}
