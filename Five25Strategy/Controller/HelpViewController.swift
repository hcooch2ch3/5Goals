//
//  HelpViewController.swift
//  FiveTwoFiveRule
//
//  Created by 임성민 on 2020/08/19.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import UIKit

class HelpViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UserDefaults.standard.bool(forKey: "Use") == false {
            UserDefaults.standard.set(true, forKey: "Use")
            
            /// Hide back button when first read help to prevent confusing user.
            self.navigationItem.setHidesBackButton(true, animated: true)
        }
    }
    
    @IBAction func touchUpExitButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
