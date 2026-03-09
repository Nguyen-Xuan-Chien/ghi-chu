import Foundation
import SQLite3

class DatabaseHelper {

    static let shared = DatabaseHelper()
    private var db: OpaquePointer?

    private init() {
        openDatabase()
        createTable()
    }

    // MARK: - Open DB
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

    // MARK: - Create Table
    func createTable() {
        let sql = """
        CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            content TEXT,
            dateISO TEXT
        );
        """

        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            print("❌ Lỗi tạo bảng notes.")
        } else {
            print("✔️ Tạo bảng notes OK.")
        }
    }

    // MARK: - Insert
    func insertNote(title: String, content: String, dateISO: String) {
        let sql = "INSERT INTO notes (title, content, dateISO) VALUES (?, ?, ?);"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {

            sqlite3_bind_text(stmt, 1, (title as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (content as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (dateISO as NSString).utf8String, -1, nil)

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

    // MARK: - Get all notes
    func getAllNotes() -> [Note] {

        let sql = "SELECT id, title, content, dateISO FROM notes ORDER BY id DESC;"
        var stmt: OpaquePointer?
        var list: [Note] = []

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {

            while sqlite3_step(stmt) == SQLITE_ROW {

                let id = sqlite3_column_int64(stmt, 0)
                let title = String(cString: sqlite3_column_text(stmt, 1))
                let content = String(cString: sqlite3_column_text(stmt, 2))
                let dateISO = String(cString: sqlite3_column_text(stmt, 3))

                let note = Note(id: id, title: title, content: content, dateISO: dateISO)
                list.append(note)
            }

        } else {
            let errmsg = String(cString: sqlite3_errmsg(db!))
            print("❌ Lỗi getAllNotes: \(errmsg)")
        }

        sqlite3_finalize(stmt)
        return list
    }

    // MARK: - Delete by ID
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

    // MARK: - Delete DB files (reset hoàn toàn database)
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
        SET title = ?, content = ?, dateISO = ?
        WHERE id = ?
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {

            sqlite3_bind_text(statement, 1, (note.title as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (note.content as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (note.dateISO as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(statement, 4, note.id)

            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ Update note thành công")
            } else {
                print("❌ Update note thất bại")
            }
        }

        sqlite3_finalize(statement)
    }

}
