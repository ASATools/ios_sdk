//
//  AppDelegate.swift
//  ASAAttribution
//
//  Created by vdugnist on 11/16/2021.
//  Copyright (c) 2021 vdugnist. All rights reserved.
//

import UIKit
import ASATools

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    public static let defaultsKey = "asatools_example_response"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        ASATools.instance.attribute(apiToken: "6a49166d-cd10-43b9-94ed-3423b55172ff") { response, error in
            guard let response = response else {
                if let error = error {
                    self.updateWith(result: "error: " + error.localizedDescription)
                }
                return
            }

            var result = "response status: " + response.status.description()
            result += "\n" + "response keyword: " + (response.result?.keywordName ?? "unknown")
            
            if let data = try? JSONSerialization.data(withJSONObject: response.analyticsValues(),
                                                      options: [.prettyPrinted]),
               let formattedString = String(data: data, encoding: .utf8) {
                result += "\n" + "analytics values: " + formattedString
            }
            
            self.updateWith(result: result)
        }

        return true
    }

    private func updateWith(result: String) {
        (self.window?.rootViewController as? ViewController)?.display(text: result)
        UserDefaults.standard.set(result, forKey: AppDelegate.defaultsKey)
    }
}

