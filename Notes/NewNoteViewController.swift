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
import AVFoundation

class NewNoteViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, SFSpeechRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
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
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    
    var captureSession: AVCaptureSession!
    var capturePhotoOutput: AVCapturePhotoOutput!

    @IBAction func cameraButton(_ sender: UIButton) {
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        if (captureDevice == nil) {
            let alert = UIAlertController(title: "Błąd aparatu", message: "Urządzenie nie posiada aparatu! Czy chcesz wybrać zdjęcie z galerii?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Nie", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Tak", style: .default, handler: { action in
                self.pickImageFromGallery()
                return
            }))
            self.present(alert, animated: true)
            return
        }
        var input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: captureDevice!)
        } catch {
            fatalError("Error configuring capture device: \(error)");
        }
        captureSession = AVCaptureSession()
        captureSession.addInput(input)
        
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
        captureSession.startRunning()
    }
    
    var imagePicker = UIImagePickerController()
    
    func pickImageFromGallery() {
        if (UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum)) {
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!) {
        self.dismiss(animated: true, completion: { () -> Void in
        })
        applyOCR(img: image)
    }
    
    let activityView = UIActivityIndicatorView()
    func showActivityIndicator() {
        activityView.center = view.center
        activityView.hidesWhenStopped = true
        activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        activityView.color = UIColor(red: 238.0 / 255.0, green: 211.0 / 255.0, blue: 26.0 / 225.0, alpha: 1.0)
        activityView.color = UIColor(red: 15.0 / 255.0, green: 164.0 / 255.0, blue: 145.0 / 225.0, alpha: 1.0)
        view.addSubview(activityView)
        activityView.startAnimating()
    }
    
    func setNoteBody(text: String) {
        DispatchQueue.main.async {
            self.bodyInput.text = text
            self.activityView.stopAnimating()
        }
    }
    
    func applyOCR(img: UIImage) {
        showActivityIndicator()
        let imageData: NSData = UIImageJPEGRepresentation(img, 0.2)! as NSData
        let base64 = imageData.base64EncodedString(options: .endLineWithCarriageReturn)
        let body = "{ 'requests': [ { 'image': { 'content': '\(base64)' }, 'features': [ { 'type': 'DOCUMENT_TEXT_DETECTION' } ],  'imageContext': {'languageHints': ['en']} } ] }";
        let session = URLSession.shared
        let url = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=google api key")
        let request = NSMutableURLRequest(url: url!, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            data,
            response,
            error in
            if let error = error {
                print(error.localizedDescription)
                //TODO: error
            }
            if let data = data {
                do {
                    var json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as![String: Any]
                    if let responseData = json["responses"] as? NSArray {
                        if let levelB = responseData[0] as? [String: Any] {
                            if let levelC = levelB["fullTextAnnotation"] as? [String: Any] {
                                if let text = levelC["text"] as? String {
                                    self.setNoteBody(text: text)
                                    return
                                }
                            }
                        }
                    }
                    let error = NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invaild access token"])
                    print("error parsing \(error)")
                    //TODO: error
                    return
                } catch {
                    print("error parsing \(error)")
                    //TODO: error
                    return
                }
            }
        })
        task.resume()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if (captureSession == nil) {
            super.viewWillDisappear(animated)
            return
        }
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
    
    private func setupPhotoOutput() {
        capturePhotoOutput = AVCapturePhotoOutput()
        capturePhotoOutput.isHighResolutionCaptureEnabled = true
        captureSession.addOutput(capturePhotoOutput!)
    }
    
}

extension NewNoteViewController : AVCapturePhotoCaptureDelegate {
    
    private func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        capturePhotoOutput?.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil else {
            fatalError("Failed to capture photo: \(String(describing: error))")
        }
        guard let imageData = photo.fileDataRepresentation() else {
            fatalError("Failed to convert pixel buffer")
        }
        guard let image = UIImage(data: imageData) else {
            fatalError("Failed to convert image data to UIImage")
        }
        self.applyOCR(img: image)
    }
    
}
