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
        
        ASAAttribution.sharedInstance.attribute(apiToken: "6a49166d-cd10-43b9-94ed-3423b55172ff") { response, error in
            guard let response = response else {
                if let error = error {
                    print("error: " + error.localizedDescription)
                }
                return
            }

            print("response status: " + response.status.description())
            print("response keyword: " + (response.result?.keywordName ?? "unknown"))
            
            if let data = try? JSONSerialization.data(withJSONObject: response.analyticsValues(),
                                                      options: [.prettyPrinted]),
               let formattedString = String(data: data, encoding: .utf8) {
                print("analytics values: " + formattedString)
            }
        }

        return true
    }

}

