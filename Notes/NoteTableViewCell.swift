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
    @IBOutlet weak var doneCheckBox: CheckBox2!
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
            note!.done = doneCheckBox.getChecked()
            db.updateNote(noteToUpdate: note!)
            if (tableController != nil) {
                tableController!.loadNotes()
            }
        }
    }
    
    func setDone() {
        if (doneCheckBox.getChecked()) {
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
    
    @IBAction func editButton(_ sender: UIButton) {
        if (note != nil) {
            db.deleteByID(id: note!.id)
        }
        if (tableController != nil) {
            tableController!.loadNotes()
        }
    }
    
}
