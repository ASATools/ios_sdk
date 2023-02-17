//
//  ASATools+updateUserId.swift
//  ASATools
//
//  Created by Vladislav Dugnist on 2/16/23.
//

import Foundation

extension ASATools {
    func syncNewUserIdIfNeeded(completion: ((Bool) -> ())?) -> Bool {
        let oldUserId = self.userID
        guard let newUserId = UserDefaults.standard.string(forKey: ASATools.newUserIdDefaultsKey),
              newUserId != oldUserId,
              let apiToken = self.apiToken,
              !self.isSyncingUserId,
              !self.isSyncingPurchases,
              !(self.libInitialized && !self.attributionCompleted)
        else {
            return false
        }
        
        self.isSyncingUserId = true
        
        let parameters = [
            "old_user_id": oldUserId,
            "new_user_id": newUserId,
            "application_token": apiToken
        ]

        var request = URLRequest(url: URL(string: "https://asa.tools/api/attribution/update_user_id")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.queue.async {
                self.isSyncingUserId = false
                guard let data = data,
                      let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject],
                      let status = responseJSON["status"] as? String,
                      status == "ok" else {
                        completion?(false)
                        return
                      }

                UserDefaults.standard.set(newUserId, forKey: ASATools.userIdDefaultsKey)
                UserDefaults.standard.removeObject(forKey: ASATools.newUserIdDefaultsKey)
                completion?(true)
            }
        }.resume()
        return true
    }
}
