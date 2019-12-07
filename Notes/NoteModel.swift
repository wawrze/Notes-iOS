//
//  NoteModel.swift
//  Notes
//
//  Created by mw on 06.12.2019.
//  Copyright © 2019 mw. All rights reserved.
//

import Foundation

class NoteModel {
    
    var id: Int = 0
    var title: String = ""
    var body: String = ""
    var date: Date = Date()
    var secured: Bool = false
    var done: Bool = false
    
    init(id: Int, title: String, body: String, date: Date, secured: Bool, done: Bool) {
        self.id = id
        self.title = title
        self.body = body
        self.date = date
        self.secured = secured
        self.done = done
    }
    
}
