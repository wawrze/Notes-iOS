//
//  CalendarEvent.swift
//  Notes
//
//  Created by mw on 22.12.2019.
//  Copyright © 2019 mw. All rights reserved.
//

import Foundation

class CalendarEvent {
    
    var id: String = ""
    var noteId: Int = 0
    var googleUser: String = ""
    
    init(id: String, noteId: Int, googleUser: String) {
        self.id = id
        self.noteId = noteId
        self.googleUser = googleUser
    }
    
}
