//
//  ViewController.swift
//  Notes
//
//  Created by mw on 06.12.2019.
//  Copyright © 2019 mw. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    // MARK: Properties
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var bodyInput: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    //@IBOutlet weak var googleSection: UIStackView!
    @IBOutlet weak var googleCheckBox: CheckBox!
    
    //@IBOutlet weak var securitySection: UIStackView!
    @IBOutlet weak var securityCheckBox: CheckBox!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleInput.delegate = self
        bodyInput.delegate = self
    }

    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: UITextViewDelegate
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    // MARK: Actions
    @IBAction func cameraButton(_ sender: UIButton) {

    }
    
    @IBAction func microphoneButton(_ sender: UIButton) {

    }
    
    @IBAction func addButton(_ sender: UIButton) {
        let title = "title: " + titleInput.text!
        NSLog(title)
        let body = "body: " + bodyInput.text
        NSLog(body)
        if (securityCheckBox.isChecked) {
            NSLog("security checked")
        } else {
            NSLog("security unchecked")
        }
        if (googleCheckBox.isChecked) {
            NSLog("google checked")
        } else {
            NSLog("google unchecked")
        }
        let date = datePicker.date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full
        var dateString = "date: "
        dateString += dateFormatter.string(from: date)
        NSLog(dateString)
    }
    
}
