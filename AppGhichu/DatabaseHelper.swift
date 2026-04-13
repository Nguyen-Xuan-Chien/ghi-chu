import Foundation
import SQLite3

class DatabaseHelper {

    static let shared = DatabaseHelper()
    private var db: OpaquePointer?

    private init() {
        openDatabase()
        createTable()
    }

    func openDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("notes.sqlite")

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("❌ Không thể mở database.")
            return
        }

        print("📂 DB path: \(fileURL.path)")
    }

    func createTable() {
        let sql = """
        CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            content TEXT,
            dateISO TEXT,
            colorHex TEXT,
            textColorHex TEXT,
            emoji TEXT
        );
        """

        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            print("❌ Lỗi tạo bảng notes.")
        } else {
            print("✔️ Tạo bảng notes OK.")
            let alterSql = "ALTER TABLE notes ADD COLUMN colorHex TEXT;"
            sqlite3_exec(db, alterSql, nil, nil, nil) 
            let alterTextSql = "ALTER TABLE notes ADD COLUMN textColorHex TEXT;"
            sqlite3_exec(db, alterTextSql, nil, nil, nil)
            let alterEmojiSql = "ALTER TABLE notes ADD COLUMN emoji TEXT;"
            sqlite3_exec(db, alterEmojiSql, nil, nil, nil)
        }
    }

    func insertNote(title: String, content: String, dateISO: String, colorHex: String? = nil, textColorHex: String? = nil, emoji: String? = nil) {
        let sql = "INSERT INTO notes (title, content, dateISO, colorHex, textColorHex, emoji) VALUES (?, ?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {

            sqlite3_bind_text(stmt, 1, (title as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (content as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (dateISO as NSString).utf8String, -1, nil)
            if let hex = colorHex {
                sqlite3_bind_text(stmt, 4, (hex as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 4)
            }
            if let tHex = textColorHex {
                sqlite3_bind_text(stmt, 5, (tHex as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 5)
            }
            if let emj = emoji {
                sqlite3_bind_text(stmt, 6, (emj as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 6)
            }

            if sqlite3_step(stmt) == SQLITE_DONE {
                print("📝 Thêm note thành công.")
            } else {
                let errmsg = String(cString: sqlite3_errmsg(db!))
                print("❌ Lỗi thêm note: \(errmsg)")
            }

        } else {
            let errmsg = String(cString: sqlite3_errmsg(db!))
            print("❌ Lỗi prepare insertNote: \(errmsg)")
        }

        sqlite3_finalize(stmt)
    }

    func getAllNotes() -> [Note] {

        let sql = "SELECT id, title, content, dateISO, colorHex, textColorHex, emoji FROM notes ORDER BY id DESC;"
        var stmt: OpaquePointer?
        var list: [Note] = []

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {

            while sqlite3_step(stmt) == SQLITE_ROW {

                let id = sqlite3_column_int64(stmt, 0)
                let title = String(cString: sqlite3_column_text(stmt, 1))
                let content = String(cString: sqlite3_column_text(stmt, 2))
                let dateISO = String(cString: sqlite3_column_text(stmt, 3))
                
                var colorHex: String? = nil
                if let cStr = sqlite3_column_text(stmt, 4) {
                    colorHex = String(cString: cStr)
                }
                
                var textColorHex: String? = nil
                if let tcStr = sqlite3_column_text(stmt, 5) {
                    textColorHex = String(cString: tcStr)
                }
                
                var emoji: String? = nil
                if let eStr = sqlite3_column_text(stmt, 6) {
                    emoji = String(cString: eStr)
                }

                let note = Note(id: id, title: title, content: content, dateISO: dateISO, colorHex: colorHex, textColorHex: textColorHex, emoji: emoji)
                list.append(note)
            }

        } else {
            let errmsg = String(cString: sqlite3_errmsg(db!))
            print("❌ Lỗi getAllNotes: \(errmsg)")
        }

        sqlite3_finalize(stmt)
        return list
    }

    func deleteNote(id: Int64) {
        let sql = "DELETE FROM notes WHERE id = ?;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {

            sqlite3_bind_int64(stmt, 1, id)

            if sqlite3_step(stmt) == SQLITE_DONE {
                print("🗑️ Xoá note id=\(id) thành công.")
            } else {
                let errmsg = String(cString: sqlite3_errmsg(db!))
                print("❌ Lỗi xoá note id=\(id): \(errmsg)")
            }
        } else {
            let errmsg = String(cString: sqlite3_errmsg(db!))
            print("❌ Lỗi prepare deleteNote: \(errmsg)")
        }

        sqlite3_finalize(stmt)
    }

    // MARK: - Delete all notes
    func deleteAllNotes() {
        guard let db = db else {
            print("⚠️ Không thể xoá vì DB chưa mở.")
            return
        }

        let sql = "DELETE FROM notes;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {

            if sqlite3_step(stmt) == SQLITE_DONE {
                print("🧹 Xoá toàn bộ ghi chú thành công.")
            } else {
                let errmsg = String(cString: sqlite3_errmsg(db))
                print("❌ Lỗi khi xoá tất cả ghi chú: \(errmsg)")
            }

        } else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("❌ Lỗi prepare deleteAllNotes: \(errmsg)")
        }

        sqlite3_finalize(stmt)
    }

    func resetDatabaseFile() {
        let fm = FileManager.default
        let folder = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

        let files = [
            folder.appendingPathComponent("notes.sqlite"),
            folder.appendingPathComponent("notes.sqlite-wal"),
            folder.appendingPathComponent("notes.sqlite-shm")
        ]

        for file in files {
            if fm.fileExists(atPath: file.path) {
                try? fm.removeItem(at: file)
                print("🗑 Xoá file: \(file.lastPathComponent)")
            }
        }

        print("🔄 Database đã reset, sẽ tạo lại khi app chạy.")
    }
    func updateNote(_ note: Note) {
        let sql = """
        UPDATE notes
        SET title = ?, content = ?, dateISO = ?, colorHex = ?, textColorHex = ?, emoji = ?
        WHERE id = ?
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {

            sqlite3_bind_text(statement, 1, (note.title as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (note.content as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (note.dateISO as NSString).utf8String, -1, nil)
            if let hex = note.colorHex {
                sqlite3_bind_text(statement, 4, (hex as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 4)
            }
            if let tHex = note.textColorHex {
                sqlite3_bind_text(statement, 5, (tHex as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 5)
            }
            if let emj = note.emoji {
                sqlite3_bind_text(statement, 6, (emj as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 6)
            }
            sqlite3_bind_int64(statement, 7, note.id)

            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ Update note thành công")
            } else {
                print("❌ Update note thất bại")
            }
        }

        sqlite3_finalize(statement)
    }

}
