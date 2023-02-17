//
//  ViewController.swift
//  ASAAttribution
//
//  Created by vdugnist on 11/16/2021.
//  Copyright (c) 2021 vdugnist. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet public weak var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let result = UserDefaults.standard.string(forKey: AppDelegate.defaultsKey) {
            self.display(text: "cached: " + result)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func display(text: String) {
        self.label.textAlignment = .left
        self.label.text = text
    }
}

