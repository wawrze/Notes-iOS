//
//  ViewController.swift
//  Notes
//
//  Created by mw on 06.12.2019.
//  Copyright © 2019 mw. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, SFSpeechRecognizerDelegate {
  
    var db = DBHelper.get()
    
    var notes:[NoteModel] = []
    
    // MARK: Properties
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var bodyInput: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var microphoneImage: UIButton!
    
    //@IBOutlet weak var googleSection: UIStackView!
    @IBOutlet weak var googleCheckBox: CheckBox!
    
    //@IBOutlet weak var securitySection: UIStackView!
    @IBOutlet weak var securityCheckBox: CheckBox!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleInput.delegate = self
        bodyInput.delegate = self
    }
    
    // MARK: VoiceRecognition
    // from https://medium.com/ios-os-x-development/speech-recognition-with-swift-in-ios-10-50d5f4e59c48
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var recognitionInProgress = false
    
    @IBAction func microphoneButton(_ sender: UIButton) {
        if (recognitionInProgress) {
            recognitionInProgress = false
            let image = UIImage(named: "ic_microphone")?.withRenderingMode(.alwaysTemplate)
            microphoneImage.setImage(image, for: .normal)
            microphoneImage.tintColor = UIColor.black
            self.recognitionTask?.finish()
        } else {
            recognitionInProgress = true
            let image = UIImage(named: "ic_microphone")?.withRenderingMode(.alwaysTemplate)
            microphoneImage.setImage(image, for: .normal)
            microphoneImage.tintColor = UIColor.red
            self.recordAndRecognizeSpeech()
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
    
    @IBAction func addButton(_ sender: UIButton) {
        if (titleInput.text != nil && !titleInput.text!.isEmpty) {
            let id_ = db.read().count + 1
            db.insertNote(id: id_, title: titleInput.text!, body: bodyInput.text, date: datePicker.date, secured: securityCheckBox.isChecked, done: false)
        }
        // TODO: send to Google if checkbox is checked
    }
    
}
