//
//  NoteDetailsViewController.swift
//  Notes
//
//  Created by mw on 27.12.2019.
//  Copyright © 2019 mw. All rights reserved.
//

import UIKit
import LocalAuthentication

class NoteDetailsViewController: UIViewController {
    
    var db = DBHelper.get()
    var note: NoteModel?
    
    @IBOutlet weak var noteTitleLabel: UILabel!
    @IBOutlet weak var noteBodyLabel: UILabel!
    @IBOutlet weak var noteDateLabel: UILabel!
    @IBOutlet weak var noteTitle: UILabel!
    @IBOutlet weak var noteBody: UITextView!
    @IBOutlet weak var noteDate: UILabel!
    @IBOutlet weak var googleSection: UIStackView!
    @IBOutlet weak var securitySection: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noteTitleLabel.isHidden = true
        noteBodyLabel.isHidden = true
        noteDateLabel.isHidden = true
        noteTitle.isHidden = true
        noteBody.isHidden = true
        noteDate.isHidden = true
        googleSection.isHidden = true
        securitySection.isHidden = true
        if (note != nil) {
            if (note!.secured) {
                authenticationWithTouchID()
            } else {
                bindNote()
            }
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    func bindNote() {
        DispatchQueue.main.async {
            if (self.note != nil) {
                self.noteTitleLabel.isHidden = false
                self.noteBodyLabel.isHidden = false
                self.noteDateLabel.isHidden = false
                self.noteTitle.isHidden = false
                self.noteBody.isHidden = false
                self.noteDate.isHidden = false
                
                self.noteTitle.text = self.note!.title
                self.noteBody.text = self.note!.body
            
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd hh:mm"
                self.noteDate.text = df.string(from: self.note!.date)
            
                let user = self.db.getGoogleUser()
                self.googleSection.isHidden = self.note!.calendarEventId.isEmpty || user == nil
                self.securitySection.isHidden = !(self.note!.secured)
            }
        }
    }

    func authError(msg: String) {
        let alert = UIAlertController(title: "Błąd autoryzacji", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true)
    }
    
}

extension NoteDetailsViewController {
    
    func authenticationWithTouchID() {
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.localizedFallbackTitle = "Użyj kodu dostępu"
        
        var authError: NSError?
        let reasonString = "Autoryzuj w celu wyświetlenia zawartości notatki"
        
        if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString) { success, evaluateError in
                if success {
                   self.bindNote()
                } else {
                    guard let error = evaluateError else {
                        return
                    }
                    let _msg = self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code)
                    self.authError(msg: _msg)
                }
            }
        } else {
            guard let error = authError else {
                return
            }
            let _msg = self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code)
            self.authError(msg: _msg)
        }
    }
    
    func evaluatePolicyFailErrorMessageForLA(errorCode: Int) -> String {
        var message = ""
        if #available(iOS 11.0, macOS 10.13, *) {
            switch errorCode {
            case LAError.biometryNotAvailable.rawValue:
                message = "Nie można przeprowadzić autoryzacji, ponieważ urządzenie nie obsługuje biometrii."
                
            case LAError.biometryLockout.rawValue:
                message = "Nie można przeprowadzić autoryzacji, ponieważ autoryzacja nie powiodła się zbyt wiele razy."
                
            case LAError.biometryNotEnrolled.rawValue:
                message = "Nie można przeprowadzić autoryzacji, ponieważ biometria nie została skonfigurowana."
                
            default:
                message = "Nieznany błąd autoryzacji."
            }
        } else {
            switch errorCode {
            case LAError.touchIDLockout.rawValue:
                message = "Zbyt wiele nieudanych prób."
                
            case LAError.touchIDNotAvailable.rawValue:
                message = "TouchID jest niedostępne na tym urządzeniu."
                
            case LAError.touchIDNotEnrolled.rawValue:
                message = "TouchID nie zostało skonfigurowane na tym urządzeniu."
                
            default:
                message = "Nieznany błąd TouchID."
            }
        }
        
        return message;
    }
    
    func evaluateAuthenticationPolicyMessageForLA(errorCode: Int) -> String {
        
        var message = ""
        
        switch errorCode {
            
        case LAError.authenticationFailed.rawValue:
            message = "Autoryzacja nie powiodła się."
            
        case LAError.appCancel.rawValue:
            message = "Autoryzacja została anulowana przez aplikację."
            
        case LAError.invalidContext.rawValue:
            message = "Nieprawidłowy kontekst."
            
        case LAError.notInteractive.rawValue:
            message = "Not interactive"
            
        case LAError.passcodeNotSet.rawValue:
            message = "Passcode nie został skonfigurowany na urządzeniu."
            
        case LAError.systemCancel.rawValue:
            message = "Autoryzacja została anulowana przez system."
            
        case LAError.userCancel.rawValue:
            message = "Autoryzacja została anulowana przez użytkownika."
            
        case LAError.userFallback.rawValue:
            message = "Użytkownik anulował autoryzację."
            
        default:
            message = evaluatePolicyFailErrorMessageForLA(errorCode: errorCode)
        }
        
        return message
    }
    
}
