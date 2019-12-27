//
//  DBHelper.swift
//  Notes
//
//  Created by mw on 07.12.2019.
//  Copyright © 2019 mw. All rights reserved.
//

import Foundation
import SQLite3

// from: https://medium.com/@imbilalhassan/saving-data-in-sqlite-db-in-ios-using-swift-4-76b743d3ce0e
class DBHelper {
    
    private static var sharedDBHelper: DBHelper = {
        let dbHelper = DBHelper()
        
        return dbHelper
    }()
    
    init() {
        db = openDatabase()
        createNoteTable()
        createGoogleUserTable()
        createCalendarEventTable()
    }
    
    class func get() -> DBHelper {
        return sharedDBHelper
    }
    
    let dbPath: String = "notesDb.sqlite"
    var db: OpaquePointer?
    
    func openDatabase() -> OpaquePointer? {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(dbPath)
        var db: OpaquePointer? = nil
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
            return nil
        } else {
            print("successfully opened connection to database at \(dbPath)")
            return db
        }
    }
    
    func createNoteTable() {
        let createTableString = "CREATE TABLE IF NOT EXISTS note(Id INTEGER PRIMARY KEY, title TEXT, body TEXT, date UNSIGNED BIG INT, secured INTEGER, done INTEGER);"
        var createTableStatement: OpaquePointer? = nil
        if (sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK) {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("note table created.")
            } else {
                print("note table could not be prepared.")
            }
        } else {
            print("CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    func createGoogleUserTable() {
        let createTableString = "CREATE TABLE IF NOT EXISTS google_user(Id INTEGER PRIMARY KEY, token TEXT, account_name TEXT, mainCalendar TEXT);"
        var createTableStatement: OpaquePointer? = nil
        if (sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK) {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("google_user table created.")
            } else {
                print("google_user table could not be prepared.")
            }
        } else {
            print("CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    func createCalendarEventTable() {
        let createTableString = "CREATE TABLE IF NOT EXISTS calendar_event(Id TEXT PRIMARY KEY, note_id INTEGER, google_user TEXT);"
        var createTableStatement: OpaquePointer? = nil
        if (sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK) {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("calendar_event table created.")
            } else {
                print("calendar_event table could not be prepared.")
            }
        } else {
            print("CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    func insertNote(id: Int, title: String, body: String, date: Date, secured: Bool, done: Bool) {
        let notes = getNotes()
        for note in notes {
            if note.id == id {
                return
            }
        }
        let insertStatementString = "INSERT INTO note (Id, title, body, date, secured, done) VALUES (?, ?, ?, ?, ?, ?)"
        var insertStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(insertStatement, 1, Int32(id))
            sqlite3_bind_text(insertStatement, 2, (title as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 3, (body as NSString).utf8String, -1, nil)
            let dateMillis = date.millis
            sqlite3_bind_int64(insertStatement, 4, dateMillis)
            var securedInt: Int32
            if (secured) {
                securedInt = 1
            } else {
                securedInt = 0
            }
            sqlite3_bind_int(insertStatement, 5, securedInt)
            var doneInt: Int32
            if (done) {
                doneInt = 1
            } else {
                doneInt = 0
            }
            sqlite3_bind_int(insertStatement, 6, doneInt)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("successfully inserted note.")
            } else {
                print("could not insert note.")
            }
        } else {
            print("INSERT note could not be prepared.")
        }
        sqlite3_finalize(insertStatement)
    }

    func updateNote(noteToUpdate: NoteModel) {
        let notes = getNotes()
        var noteInDb: NoteModel? = nil
        for note in notes {
            if note.id == noteToUpdate.id {
                noteInDb = note
            }
        }
        if (noteInDb == nil) {
            return
        }
        let updateStatementString = "UPDATE note SET title = ?, body = ?, date = ?, secured = ?, done = ? WHERE Id = \(noteToUpdate.id)"
        var updateStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(updateStatement, 1, (noteToUpdate.title as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 2, (noteToUpdate.body as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(updateStatement, 3, noteToUpdate.date.millis)
            var securedInt: Int32
            if (noteToUpdate.secured) {
                securedInt = 1
            } else {
                securedInt = 0
            }
            sqlite3_bind_int(updateStatement, 4, securedInt)
            var doneInt: Int32
            if (noteToUpdate.done) {
                doneInt = 1
            } else {
                doneInt = 0
            }
            sqlite3_bind_int(updateStatement, 5, doneInt)

            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("successfully updated note.")
            } else {
                print("could not update note.")
            }
        } else {
            print("UPDATE note could not be prepared.")
        }
        sqlite3_finalize(updateStatement)
    }
    
    func getNotes() -> [NoteModel] {
        let queryStatementString = "SELECT n.*, c.id AS calendar_event_id FROM note n LEFT JOIN calendar_event c ON n.id = c.note_id AND c.google_user = (SELECT account_name FROM google_user LIMIT 1) ORDER BY done, date;"
        var queryStatement: OpaquePointer? = nil
        var notes: [NoteModel] = []
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id_ = sqlite3_column_int(queryStatement, 0)
                let title_ = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
                let body_ = String(describing: String(cString: sqlite3_column_text(queryStatement, 2)))
                let date_ = Date(milliseconds: sqlite3_column_int64(queryStatement, 3))
                var secured_: Bool
                if (sqlite3_column_int(queryStatement, 4) == 1) {
                    secured_ = true
                } else {
                    secured_ = false
                }
                var done_: Bool
                if (sqlite3_column_int(queryStatement, 5) == 1) {
                    done_ = true
                } else {
                    done_ = false
                }
                let cEId = sqlite3_column_text(queryStatement, 6)
                var calendarEventId_: String
                if (cEId != nil) {
                    calendarEventId_ = String(describing: String(cString: cEId!))
                } else {
                    calendarEventId_ = ""
                }
                let note = NoteModel(id: Int(id_), title: title_, body: body_, date: date_, secured: secured_, done: done_)
                note.calendarEventId = calendarEventId_
                notes.append(note)
            }
        } else {
            print("SELECT notes statement could not be prepared.")
        }
        sqlite3_finalize(queryStatement)
        return notes
    }
    
    func getNoteById(id: Int) -> NoteModel? {
        let queryStatementString = "SELECT n.*, c.id AS calendar_event_id FROM note n LEFT JOIN calendar_event c ON n.id = c.note_id AND c.google_user = (SELECT account_name FROM google_user LIMIT 1) WHERE n.id = ? LIMIT 1;"
        var queryStatement: OpaquePointer? = nil
        var note: NoteModel? = nil
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(id))
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id_ = sqlite3_column_int(queryStatement, 0)
                let title_ = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
                let body_ = String(describing: String(cString: sqlite3_column_text(queryStatement, 2)))
                let date_ = Date(milliseconds: sqlite3_column_int64(queryStatement, 3))
                var secured_: Bool
                if (sqlite3_column_int(queryStatement, 4) == 1) {
                    secured_ = true
                } else {
                    secured_ = false
                }
                var done_: Bool
                if (sqlite3_column_int(queryStatement, 5) == 1) {
                    done_ = true
                } else {
                    done_ = false
                }
                let cEId = sqlite3_column_text(queryStatement, 6)
                var calendarEventId_: String
                if (cEId != nil) {
                    calendarEventId_ = String(describing: String(cString: cEId!))
                } else {
                    calendarEventId_ = ""
                }
                note = NoteModel(id: Int(id_), title: title_, body: body_, date: date_, secured: secured_, done: done_)
                note?.calendarEventId = calendarEventId_
            }
        } else {
            print("SELECT note statement could not be prepared.")
        }
        sqlite3_finalize(queryStatement)
        return note
    }
    
    func deleteByID(id: Int) {
        let deleteStatementString = "DELETE FROM note WHERE id = ?;"
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(deleteStatement, 1, Int32(id))
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("successfully deleted note.")
            } else {
                print("could not delete note.")
            }
        } else {
            print("DELETE note statement could not be prepared.")
        }
        sqlite3_finalize(deleteStatement)
    }
    
}

extension Date {
    var millis: Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
