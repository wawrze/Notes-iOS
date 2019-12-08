//
//  CheckBox2.swift
//  Notes
//
//  Created by mw on 07.12.2019.
//  Copyright © 2019 mw. All rights reserved.
//

import UIKit

class CheckBox2: UIButton {

    let checkedImage = UIImage(named: "ic_check_box")! as UIImage
    let uncheckedImage = UIImage(named: "ic_check_box_outline_blank")! as UIImage
    
    private var isChecked = false
    
    func setChecked(isChecked: Bool) {
        self.isChecked = isChecked
        if isChecked == true {
            self.setImage(checkedImage, for: UIControlState.normal)
        } else {
            self.setImage(uncheckedImage, for: UIControlState.normal)
        }
    }
    
    func getChecked() -> Bool {
        return isChecked
    }
    
    override func awakeFromNib() {
        self.addTarget(self, action:#selector(buttonClicked(sender:)), for: UIControlEvents.touchUpInside)
    }
    
    @objc func buttonClicked(sender: UIButton) {
        if sender == self {
            setChecked(isChecked: !self.isChecked)
        }
    }

}
