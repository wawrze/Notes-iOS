//
//  ViewController.swift
//  Notes
//
//  Created by mw on 06.12.2019.
//  Copyright © 2019 mw. All rights reserved.
//

import UIKit
import Speech
import os.log

class NewNoteViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, SFSpeechRecognizerDelegate {
  
    var db = DBHelper.get()
    
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var bodyInput: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var microphoneImage: UIButton!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var googleSection: UIStackView!
    @IBOutlet weak var googleCheckBox: CheckBox!
    
    //@IBOutlet weak var securitySection: UIStackView!
    @IBOutlet weak var securityCheckBox: CheckBox!
    
    @IBOutlet weak var buttonsSection: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleInput.delegate = self
        bodyInput.delegate = self
        
        updateSaveButtonState()
        setGoogleSectionVisibility()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        if (titleInput.text != nil && !titleInput.text!.isEmpty) {
            let isSecureChecked = securityCheckBox.isChecked
            let _noteId = db.insertNote(title: titleInput.text!, body: bodyInput.text, date: datePicker.date, secured: isSecureChecked, done: false)
            let isGoogleChecked = googleCheckBox.isChecked
            if (isGoogleChecked) {
                let user = db.getGoogleUser()
                if (user != nil) {
                    let calendarEvent = CalendarEvent(id: 0, noteId: Int(_noteId), googleUser: user!.accountName)
                    db.insertCalendarEvent(event: calendarEvent)
                }
            }
            let alert = UIAlertController(title: "", message: "Notatka została dodana.", preferredStyle: .alert)
            self.present(alert, animated: true)
        }
    }
    
    private func setGoogleSectionVisibility() {
        let googleUser = db.getGoogleUser()
        googleSection.isHidden = googleUser == nil
    }
    
    // from https://medium.com/ios-os-x-development/speech-recognition-with-swift-in-ios-10-50d5f4e59c48
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var recognitionInProgress = false
    
    @IBAction func microphoneButton(_ sender: UIButton) {
        if (recognitionInProgress) {
            print("stopping voice recognition...")
            recognitionInProgress = false
            self.recognitionTask?.finish()
        } else {
            print("starting voice recognition...")
            recognitionInProgress = true
            self.recordAndRecognizeSpeech()
        }
        setRecognitionIcon()
    }
    
    private func setRecognitionIcon() {
        if (recognitionInProgress) {
            let image = UIImage(named: "ic_microphone")?.withRenderingMode(.alwaysTemplate)
            microphoneImage.setImage(image, for: .normal)
            microphoneImage.tintColor = UIColor.red
        } else {
            let image = UIImage(named: "ic_microphone")?.withRenderingMode(.alwaysTemplate)
            microphoneImage.setImage(image, for: .normal)
            microphoneImage.tintColor = UIColor.black
        }
    }
    
    func recordAndRecognizeSpeech() {
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            return print(error)
        }
        guard let myRecognizer = SFSpeechRecognizer() else {
            return
        }
        if !myRecognizer.isAvailable {
            return
        }
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                self.bodyInput.text = self.bodyInput.text + " " + bestString
            } else if let error = error {
                print(error)
            }
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        saveButton.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
    }
    
    private func updateSaveButtonState() {
        let text = titleInput.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    @IBAction func cameraButton(_ sender: UIButton) {
        // TODO: make document image to get text from it
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
