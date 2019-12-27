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
    private var googleLoggedIn = false
    
    func loadNotes() {
        notes = db.getNotes()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadNotes()
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
        cell.tableController = self

        return cell
    }
    
    @IBAction func unwindToNotList(sender: UIStoryboardSegue) {
        loadNotes()
    }
    
    @IBAction func googleLogIn(_ sender: UIBarButtonItem) {
        print("Google button clicked")
        if (googleLoggedIn) {
            googleLoggedIn = false
            let image = UIImage(named: "ic_google")?.withRenderingMode(.alwaysTemplate)
            googleImage.image = image
        } else {
            googleLoggedIn = true
            let image = UIImage(named: "ic_google_filled")?.withRenderingMode(.alwaysTemplate)
            googleImage.image = image
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
