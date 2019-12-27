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
        let createTableString = "CREATE TABLE IF NOT EXISTS note(id INTEGER PRIMARY KEY, title TEXT, body TEXT, date UNSIGNED BIG INT, secured INTEGER, done INTEGER);"
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
        let createTableString = "CREATE TABLE IF NOT EXISTS google_user(id INTEGER PRIMARY KEY, token TEXT, account_name TEXT, mainCalendar TEXT);"
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
        let createTableString = "CREATE TABLE IF NOT EXISTS calendar_event(id TEXT PRIMARY KEY, note_id INTEGER, google_user TEXT);"
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
    
    private func getNoteNextId() -> Int32 {
        let queryStatementString = "SELECT id FROM note ORDER BY id DESC LIMIT 1;"
        var queryStatement: OpaquePointer? = nil
        var id: Int32? = nil
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                id = sqlite3_column_int(queryStatement, 0)
            }
        } else {
            print("SELECT note next id statement could not be prepared.")
        }
        sqlite3_finalize(queryStatement)
        if (id == nil) {
            id = 0
        }
        id! += 1
        return id!
    }
    
    func insertNote(title: String, body: String, date: Date, secured: Bool, done: Bool) {
        let id = getNoteNextId()
        let insertStatementString = "INSERT INTO note (id, title, body, date, secured, done) VALUES (?, ?, ?, ?, ?, ?)"
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
    
    func deleteNoteByID(id: Int) {
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
    
    func getCalendarEvents() -> [CalendarEvent] {
        let queryStatementString = "SELECT * FROM calendar_event;"
        var queryStatement: OpaquePointer? = nil
        var calendarEvents: [CalendarEvent] = []
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id_ = String(describing: String(cString: sqlite3_column_text(queryStatement, 0)))
                let noteId_ = sqlite3_column_int(queryStatement, 1)
                let googleUser_ = String(describing: String(cString: sqlite3_column_text(queryStatement, 2)))

                let calendarEvent = CalendarEvent(id: id_, noteId: Int(noteId_), googleUser: googleUser_)
                calendarEvents.append(calendarEvent)
            }
        } else {
            print("SELECT calendar_events statement could not be prepared.")
        }
        sqlite3_finalize(queryStatement)
        return calendarEvents
    }
    
    func insertCalendarEvent(event: CalendarEvent) {
        let calendarEvents = getCalendarEvents()
        for ca in calendarEvents {
            if ca.id == event.id {
                return
            }
        }
        let insertStatementString = "INSERT INTO calendar_event (id, note_id, google_user) VALUES (?, ?, ?)"
        var insertStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 0, (event.id as NSString).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 1, Int32(event.noteId))
            sqlite3_bind_text(insertStatement, 2, (event.googleUser as NSString).utf8String, -1, nil)
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("successfully inserted calendar_event.")
            } else {
                print("could not insert calendar_event.")
            }
        } else {
            print("INSERT calendar_event could not be prepared.")
        }
        sqlite3_finalize(insertStatement)
    }
    
    func deleteCalendarEventByID(id: String) {
        let deleteStatementString = "DELETE FROM calendar_event WHERE id = ?;"
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(deleteStatement, 0, (id as NSString).utf8String, -1, nil)
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("successfully deleted calendar_event.")
            } else {
                print("could not delete calendar_event.")
            }
        } else {
            print("DELETE calendar_event statement could not be prepared.")
        }
        sqlite3_finalize(deleteStatement)
    }
    
    func insertGoogleUser(googleUser: GoogleUser) {
        deleteGoogleUser()
        let insertStatementString = "INSERT INTO google_user (id, token, accountName, mainCalendar) VALUES (?, ?, ?, ?)"
        var insertStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(insertStatement, 0, Int32(googleUser.id))
            sqlite3_bind_text(insertStatement, 1, (googleUser.token as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, (googleUser.accountName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 3, (googleUser.mainCalendar as NSString).utf8String, -1, nil)
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("successfully inserted google_user.")
            } else {
                print("could not insert google_user.")
            }
        } else {
            print("INSERT google_user could not be prepared.")
        }
        sqlite3_finalize(insertStatement)
    }
    
    func deleteGoogleUser() {
        let deleteStatementString = "DELETE FROM google_user;"
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("successfully deleted google_user.")
            } else {
                print("could not delete google_user.")
            }
        } else {
            print("DELETE google_user statement could not be prepared.")
        }
        sqlite3_finalize(deleteStatement)
    }
    
    func getGoogleUser() -> GoogleUser? {
        let queryStatementString = "SELECT * FROM google_user LIMIT 1;"
        var queryStatement: OpaquePointer? = nil
        var googleUser: GoogleUser? = nil
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id_ = sqlite3_column_int(queryStatement, 0)
                let token_ = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
                let accountName_ = String(describing: String(cString: sqlite3_column_text(queryStatement, 2)))
                let mainCalendar_ = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
                
                googleUser = GoogleUser(id: Int(id_), token: token_, accountName: accountName_, mainCalendar: mainCalendar_)
            }
        } else {
            print("SELECT google_user statement could not be prepared.")
        }
        sqlite3_finalize(queryStatement)
        return googleUser
    }
    
    func updateMainCalendar(mainCalendar: String) {
        let updateStatementString = "UPDATE google_user SET main_calendar = ?"
        var updateStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(updateStatement, 1, (mainCalendar as NSString).utf8String, -1, nil)
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("successfully updated main_calendar.")
            } else {
                print("could not update main_calendar.")
            }
        } else {
            print("UPDATE main_calendar could not be prepared.")
        }
        sqlite3_finalize(updateStatement)
    }
    
    func getMainCalendar() -> String? {
        let queryStatementString = "SELECT mainCalendar FROM google_user LIMIT 1;"
        var queryStatement: OpaquePointer? = nil
        var mainCalendar: String? = nil
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                mainCalendar = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
            }
        } else {
            print("SELECT main_calendar statement could not be prepared.")
        }
        sqlite3_finalize(queryStatement)
        return mainCalendar
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
