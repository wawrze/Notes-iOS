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
    
    @IBOutlet weak var noteTitle: UILabel!
    @IBOutlet weak var noteBody: UITextView!
    @IBOutlet weak var noteDate: UILabel!
    @IBOutlet weak var googleSection: UIStackView!
    @IBOutlet weak var securitySection: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (note != nil) {
            if (note!.secured) {
                authenticationWithTouchID()
            }
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    func bindNote() {
        if (note != nil) {
            noteTitle.text = note!.title
            noteBody.text = note!.body
            
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd hh:mm"
            noteDate.text = df.string(from: note!.date)
            
            let user = db.getGoogleUser()
            googleSection.isHidden = note!.calendarEventId.isEmpty || user == nil
            securitySection.isHidden = !(note!.secured)
        }
    }
    
    func authorizationError(message: String) {
        noteBody.text = message
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
                    let msg = self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code)
                    self.authorizationError(message: msg)
                }
            }
        } else {
            guard let error = authError else {
                return
            }
            //TODO: Show appropriate alert if biometry/TouchID/FaceID is lockout or not enrolled
            print(self.evaluateAuthenticationPolicyMessageForLA(errorCode: error.code))
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
                message = "Nie można przeprowadzić autoryzacji, ponieważ użytkownik nie skonfigurował biometrii."
                
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
            message = "Autoryzacja nieudana - nieprawidłowe dane."
            
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
