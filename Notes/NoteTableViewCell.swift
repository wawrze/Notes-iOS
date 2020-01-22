//
//  NoteTableViewCell.swift
//  Notes
//
//  Created by mw on 07.12.2019.
//  Copyright © 2019 mw. All rights reserved.
//

import UIKit

class NoteTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var doneCheckBox: UIButton!
    @IBOutlet weak var protectedIcon: UIImageView!
    @IBOutlet weak var googleIcon: UIImageView!
    
    var note: NoteModel? = nil
    let db = DBHelper.get()
    var tableController: NoteTableViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: Actions
    
    @IBAction func doneButton(_ sender: UIButton) {
        setDone()
        if (note != nil) {
            note!.done = !(note!.done)
            db.updateNote(noteToUpdate: note!)
            tableController?.loadNotes()
        }
    }
    
    func setDone() {
        if (note!.done == true) {
            let title = NSAttributedString(string: titleLabel.text!, attributes: [NSAttributedStringKey.strikethroughStyle: NSUnderlineStyle.styleSingle.rawValue])
            titleLabel.attributedText = title
            let date = NSAttributedString(string: dateLabel.text!, attributes: [NSAttributedStringKey.strikethroughStyle: NSUnderlineStyle.styleSingle.rawValue])
            dateLabel.attributedText = date
        } else {
            let title = NSAttributedString(string: titleLabel.text!, attributes: [:])
            titleLabel.attributedText = title
            let date = NSAttributedString(string: dateLabel.text!, attributes: [:])
            dateLabel.attributedText = date
        }
    }
    
    func setIcons() {
        if (note != nil) {
            protectedIcon.isHidden = !(note!.secured)
            let user = db.getGoogleUser()
            googleIcon.isHidden = note!.calendarEventId.isEmpty || user == nil
        }
    }
    
    @IBAction func editButton(_ sender: UIButton) {
        if (note != nil) {
            let alert = UIAlertController(title: "Usuwanie", message: "Czy na pewno chcesz usunąć notatkę?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Nie", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Tak", style: .default, handler: { action in
                self.db.deleteNoteByID(id: self.note!.id)
                self.tableController?.loadNotes()
            }))
            self.tableController?.present(alert, animated: true)
        }
    }
    
}
