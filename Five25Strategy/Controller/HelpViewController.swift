//
//  HelpViewController.swift
//  FiveTwoFiveRule
//
//  Created by 임성민 on 2020/08/19.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import UIKit

class HelpViewController: UIViewController {

    @IBOutlet weak var step1Label: UILabel!
    @IBOutlet weak var step2Label: UILabel!
    @IBOutlet weak var step3Label: UILabel!
    
    @IBOutlet weak var step1ImageView: UIImageView!
    @IBOutlet weak var step2ImageView: UIImageView!
    @IBOutlet weak var step3ImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UserDefaults.standard.bool(forKey: "Use") == false {
            UserDefaults.standard.set(true, forKey: "Use")
            
            /// Hide back button when first read help to prevent confusing user.
            self.navigationItem.setHidesBackButton(true, animated: true)
        }
        
        step1ImageView.image = UIImage(named: NSLocalizedString("STEP1Image", comment: ""))
        step2ImageView.image = UIImage(named: NSLocalizedString("STEP2Image", comment: ""))
        step3ImageView.image = UIImage(named: NSLocalizedString("STEP3Image", comment: ""))
        
        step1Label.text = NSLocalizedString("STEP1Text", comment: "")
        step2Label.text = NSLocalizedString("STEP2Text", comment: "")
        step3Label.text = NSLocalizedString("STEP3Text", comment: "")
    }
    
    @IBAction func touchUpExitButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
