//
//  AppDelegate.swift
//  ASAAttribution
//
//  Created by vdugnist on 11/16/2021.
//  Copyright (c) 2021 vdugnist. All rights reserved.
//

import UIKit
import ASAAttribution

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        ASAAttribution.sharedInstance.attribute(apiToken: "your_key_here") { response, error in
            if let error = error {
                // Analytics.logEvent("asa_attribution_fail", parameters: ["error_code": error.code])
                print(error)
                return
            }
            
            // Analytics.logEvent("asa_attribution_success", parameters: response!.analyticsValues()]
        }

        return true
    }

}

