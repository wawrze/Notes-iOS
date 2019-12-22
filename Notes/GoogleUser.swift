//
//  GoogleUser.swift
//  Notes
//
//  Created by mw on 22.12.2019.
//  Copyright © 2019 mw. All rights reserved.
//

import Foundation

class GoogleUser {
    
    var id: Int = 0
    var token: String = ""
    var accountName: String = ""
    var mainCalendar: String = ""
    
    init(id: Int, token: String, accountName: String, mainCalendar: String) {
        self.id = id
        self.token = token
        self.accountName = accountName
        self.mainCalendar = mainCalendar
    }
    
}
