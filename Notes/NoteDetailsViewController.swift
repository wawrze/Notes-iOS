//
//  NoteDetailsViewController.swift
//  Notes
//
//  Created by mw on 27.12.2019.
//  Copyright © 2019 mw. All rights reserved.
//

import UIKit

class NoteDetailsViewController: UIViewController {
    
    var db = DBHelper.get()
    var note: NoteModel?
    
    @IBOutlet weak var noteTitle: UILabel!
    @IBOutlet weak var noteBody: UITextView!
    @IBOutlet weak var noteDate: UILabel!
    @IBOutlet weak var googleSection: UIStackView!
    @IBOutlet weak var securitySection: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (note != nil) {
            noteTitle.text = note!.title
            noteBody.text = note!.body
         
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd hh:mm"
            noteDate.text = df.string(from: note!.date)
            
            googleSection.isHidden = note!.calendarEventId.isEmpty
            securitySection.isHidden = !(note!.secured)
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
