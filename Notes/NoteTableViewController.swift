//
//  NoteTableViewController.swift
//  Notes
//
//  Created by mw on 07.12.2019.
//  Copyright © 2019 mw. All rights reserved.
//

import UIKit

class NoteTableViewController: UITableViewController {

    // MARK: Properties
    var db = DBHelper.get()
    @IBOutlet weak var googleImage: UIBarButtonItem!
    var notes:[NoteModel] = []
    
    func loadNotes() {
        notes = db.getNotes()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadNotes()
        setGoogleIcon()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "NoteTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? NoteTableViewCell else {
            fatalError("The dequed cell is not an instance of NoteTableViewCell.")
        }

        let note = notes[indexPath.row]
        
        cell.note = note
        cell.titleLabel.text = note.title
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm"
        cell.dateLabel.text = df.string(from: note.date)
        cell.setDone()
        cell.setIcons()
        cell.tableController = self
        cell.layer.cornerRadius = 10
        cell.layer.borderWidth = 5
        cell.layer.borderColor = UIColor(red: 92.0 / 255.0, green: 154.0 / 255.0, blue: 229.0 / 255.0, alpha: 1.0).cgColor

        return cell
    }
    
    @IBAction func unwindToNotList(sender: UIStoryboardSegue) {
        loadNotes()
    }
    
    @IBAction func googleLogIn(_ sender: UIBarButtonItem) {
        let googleUser = db.getGoogleUser()
        if (googleUser != nil) {
            let alert = UIAlertController(title: "Wylogowanie", message: "Czy na pewno chcesz się wylogować z konta Google \(googleUser!.accountName)?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Nie", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Tak", style: .default, handler: { action in
                self.db.deleteGoogleUser()
                self.logoutMessage()
            }))
            self.present(alert, animated: true)
        } else {
            let user = GoogleUser(id: Int(arc4random_uniform(10000)), token: "token", accountName: "nazwa.konta@gmail.com", mainCalendar: "calendar")
            db.insertGoogleUser(googleUser: user)
            let alert = UIAlertController(title: "Logowanie", message: "Zalogowano na konto Google: \(user.accountName)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                self.setGoogleIcon()
                self.loadNotes()
            }))
            self.present(alert, animated: true)
        }
    }
    
    func logoutMessage() {
        let alert = UIAlertController(title: "Wylogowanie", message: "Wylogowano z konta Google.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.setGoogleIcon()
            self.loadNotes()
        }))
        self.present(alert, animated: true)
    }

    private func setGoogleIcon() {
        let googleUser = db.getGoogleUser()
        if (googleUser == nil) {
            let image = UIImage(named: "ic_google")?.withRenderingMode(.alwaysTemplate)
            googleImage.image = image
        } else {
            let image = UIImage(named: "ic_google_filled")?.withRenderingMode(.alwaysTemplate)
            googleImage.image = image
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
            case "AddNote":
                print("Navigating to new note view")
            case "ShowNoteDetails":
                print("Navigationg to note details view")
                let segueDestination = segue.destination
                let childViewControllers = segueDestination.childViewControllers
                guard let noteDetailViewController = childViewControllers[0] as? NoteDetailsViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
                }
                guard let selectedNoteCell = sender as? NoteTableViewCell else {
                    fatalError("Unexpected sender: \(String(describing: sender))")
                }
                guard let indexPath = tableView.indexPath(for: selectedNoteCell) else {
                    fatalError("The selected cell is not being displayed by the table")
                }
                let selectedNote = notes[indexPath.row]
                noteDetailViewController.note = selectedNote
            default:
                fatalError("Unexcepted Segue Identifier: \(String(describing: segue.identifier))")
        }
    }
    
}
