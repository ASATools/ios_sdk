//
//  ASAAttribution.swift
//  ASAAttribution
//
//  Created by Vladislav Dugnist on 16.11.2021.
//

import UIKit
import AdServices

public class ASATools: NSObject {
    @objc public static let instance = ASATools()
    internal static let libVersion = "1.4.5"
    
    private static let attributionCompletedDefaultsKey = "asa_attribution_completed"
    private static let installDateDefaultsKey = "asa_attribution_install_date"
    internal static let userIdDefaultsKey = "asa_attribution_user_id"
    internal static let newUserIdDefaultsKey = "asa_attribution_new_user_id"
    internal static let purchaseEvents = "asa_attribution_purchase_events"
    internal static let retentionRate = "asa_attribution_retention_rate"
    
    // 3 attempts with 5 seconds delay as in documentation for AAAttribution.attributionToken()
    private var appleAttributionRequestsAttempts: Int = 3
    private let appleAttributionRequestDelay: TimeInterval = 5.0
    private var attributionTokenGenerationRequestsAttempts: Int = 3
    private let attributionTokenGenerationRequestsDelay: TimeInterval = 3.0
    internal var libInitialized = false

    internal let queue = DispatchQueue(label: "asatools", qos: .utility)
    internal var isSyncingPurchases: Bool = false
    internal var isSyncingUserId: Bool = false
    internal var apiToken: String? = nil
    internal var storeKit2ListenerTask: Any? = nil
    internal lazy var purchasedEvents: [ASAToolsPurchaseEvent] = {
        return getPurchaseEvents() ?? []
    }()
    
    public override init() {
        super.init()
        
        let purchasesMigratedKey = "asaattribution_purchases_migrated_1.4.0"
        if UserDefaults.standard.bool(forKey: purchasesMigratedKey) == false {
            UserDefaults.standard.removeObject(forKey: ASATools.purchaseEvents)
            UserDefaults.standard.set(true, forKey: purchasesMigratedKey)
        }

        self.subscribeToPaymentQueue()
    }

    @objc public var userID: String {
        get {
            if let result = UserDefaults.standard.string(forKey: ASATools.userIdDefaultsKey) {
                return result
            }
            
            let result = UUID().uuidString
            UserDefaults.standard.set(result, forKey: ASATools.userIdDefaultsKey)
            return result
        }
        set {
            if newValue == self.userID {
                return
            }

            if !self.libInitialized {
                UserDefaults.standard.set(newValue, forKey: ASATools.userIdDefaultsKey)
            } else {
                UserDefaults.standard.set(newValue, forKey: ASATools.newUserIdDefaultsKey)
                self.queue.async {
                    _ = self.syncNewUserIdIfNeeded(completion: nil)
                }
            }
        }
    }

    @objc private var firstInstallOnDevice: Bool {
        set {
            KeychainWrapper.storeBool(newValue, forKey: "first_install_on_device")
        }
        get {
            return KeychainWrapper.boolValueFor(key: "first_install_on_device") ?? true
        }
    }

    @objc private var firstInstallOnAccount: Bool {
        set {
            KeychainWrapper.storeBool(newValue, forKey: "first_install_on_account", syncInKeychain: true)
        }
        get {
            return KeychainWrapper.boolValueFor(key: "first_install_on_account", syncInKeycnain: true) ?? true
        }
    }

    @objc private var initialUserID: String? {
        set {
            KeychainWrapper.storeString(self.userID, forKey: "initial_user_id")
        }
        get {
            return KeychainWrapper.stringValueFor(key: "initial_user_id")
        }
    }

    var installDate: TimeInterval = {
        if let date = UserDefaults.standard.object(forKey: ASATools.installDateDefaultsKey) as? Date  {
            return date.timeIntervalSince1970
        }
        
        let date = Date()
        UserDefaults.standard.set(date, forKey: ASATools.installDateDefaultsKey)
        return date.timeIntervalSince1970
    }()
        
    internal var attributionCompleted: Bool {
        get {
            return UserDefaults.standard.bool(forKey: ASATools.attributionCompletedDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: ASATools.attributionCompletedDefaultsKey)
        }
    }

    @objc public func attribute(apiToken: String,
                          completion: ((_ response: AttributionResponse?, _ error: Error?) -> ())? = nil) {
        if apiToken.count != 36 {
            #if DEBUG
            fatalError("Please provide API key from ASATools dashboard settings")
            #else
            return
            #endif
        }

        self.queue.async {
            if self.libInitialized {
                return
            }

            self.libInitialized = true
            self.apiToken = apiToken
            
            if self.syncNewUserIdIfNeeded(completion: { completed in
                self.attribute(apiToken: apiToken, completion: completion)
            }) {
                return
            }

            if self.attributionCompleted {
                self.syncPurchasedEvents()
                #if DEBUG
                print("ASATools: loading stored attribution")
                #endif
                return
            }

            if #available(iOS 14.3, *) {
                self.attributeWith(apiToken: apiToken) { response, error in
                    if response != nil {
                        self.syncPurchasedEvents()
                    }
                    
                    DispatchQueue.main.async {
                        #if DEBUG
                        print("ASATools: attribution " + ((error == nil) ? "successful" : "error: \(String(describing: error?.localizedDescription)))"))
                        #endif
                        completion?(response, error)
                    }
                }
            } else {
                self.attributionCompleted = true
                DispatchQueue.main.async {
                    #if DEBUG
                    print("ASATools: attribution available only for iOS 14.3+")
                    #endif
                    completion?(nil, ASAToolsErrorCodes.unsupportedIOSVersion.error())
                }
            }
        }
    }

    @available(iOS 14.3, *)
    private func attributeWith(apiToken: String,
                               completion: @escaping (_ response: AttributionResponse?, _ error: Error?) -> ()) {
        let attributionToken: String
        let installDate = self.installDate

        do {
            try attributionToken = AAAttribution.attributionToken()
        } catch {
            if self.attributionTokenGenerationRequestsAttempts > 0 {
                self.attributionTokenGenerationRequestsAttempts -= 1
                self.queue.asyncAfter(deadline: DispatchTime.now() + self.attributionTokenGenerationRequestsDelay) {
                    self.attributeWith(apiToken: apiToken, completion: completion)
                }
            } else {
                completion(nil, ASAToolsErrorCodes.errorGeneratingAttributionToken.error())
            }
            return
        }

        self.attributeASAToken(attributionToken) { response, error in
            self.attributeASATokenResponse(attributionToken: attributionToken,
                                           apiToken: apiToken,
                                           installDate: installDate,
                                           asaResponse: response,
                                           completion: completion)
        }
    }

    private func attributeASAToken(_ token: String,
                        completion: @escaping (_ response: [String: AnyHashable]?, _ error: Error?) -> ()) {
        var request = URLRequest(url: URL(string:"https://api-adservices.apple.com/api/v1/")!)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(token.utf8)
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.queue.async {
                if let error = error {
                    completion(nil, ASAToolsErrorCodes.errorResponseFromAppleAttribution.error(message: "error response: \(error.localizedDescription)"))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(nil, ASAToolsErrorCodes.errorResponseFromAppleAttribution.error(message: "response type: \(String(describing: type(of: response))) data: \(String(data: data ?? Data(), encoding: .utf8) ?? "none")"))
                    return
                }

                if httpResponse.statusCode != 200 && self.appleAttributionRequestsAttempts > 0 {
                    self.appleAttributionRequestsAttempts -= 1
                    self.queue.asyncAfter(deadline: DispatchTime.now() + self.appleAttributionRequestDelay) {
                        self.attributeASAToken(token, completion: completion)
                    }
                    return
                }
                
                guard let data = data,
                      let result = try? JSONSerialization.jsonObject(with: data, options: [])
                        as? [String: AnyHashable] else {
                            completion(nil, ASAToolsErrorCodes.errorResponseFromAppleAttribution.error(message: "status code: \(httpResponse.statusCode)"))
                          return
                      }

                completion(result, nil)
            }
        }.resume()
    }
    
    private func attributeASATokenResponse(attributionToken: String,
                                           apiToken: String,
                                           installDate: TimeInterval,
                                           asaResponse: [String: AnyHashable]?,
                                           completion: @escaping (_ response: AttributionResponse?,
                                                                  _ error: Error?) -> ()) {
        var request = URLRequest(url: URL(string:"https://asa.tools/api/attribution")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var bodyJSON: [String: AnyHashable] = ["application_token": apiToken,
                                               "attribution_token": attributionToken,
                                               "user_id": self.userID,
                                               "lib_version": ASATools.libVersion,
                                               "os_version": self.osVersion(),
                                               "first_install_on_device": self.firstInstallOnDevice,
                                               "first_install_on_account": self.firstInstallOnAccount,
                                               "install_date": installDate]
        bodyJSON["app_version"] = self.appVersion()
        bodyJSON["asa_attribution_response"] = asaResponse
        bodyJSON["initial_user_id"] = self.initialUserID
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyJSON, options: [])
        
        URLSession.shared.dataTask(with: request) { optionalData, response, error in
            self.queue.async {
                guard error == nil,
                      let data = optionalData,
                      let responseJSON = (try? JSONSerialization.jsonObject(with: data, options: []))
                        as? [String: AnyHashable] else {
                          completion(nil, ASAToolsErrorCodes.errorResponseFromASATools.error(message: "response is empty or not a json: \(String(data: optionalData ?? Data(), encoding: .utf8) ?? "none") statusCode: \((response as? HTTPURLResponse)?.statusCode ?? 0)"))
                          return
                      }

                guard let responseStatus = responseJSON["status"] as? String,
                        responseStatus == "ok" else {
                            completion(nil, ASAToolsErrorCodes.errorResponseFromASATools.error(message: "ASATools error response: " + (responseJSON["error_message"] as? String ?? "")))
                            return
                }
                
                guard let status = responseJSON["attribution_status"] as? String else {
                    completion(nil, ASAToolsErrorCodes.errorResponseFromASATools.error(message: "attribution status is empty"))
                    return
                }

                switch status {
                case "attributed": break
                case "organic":
                    self.attributionCompleted = true
                    self.firstInstallOnDevice = false
                    self.firstInstallOnAccount = false
                    if self.initialUserID == nil {
                        self.initialUserID = self.userID
                    }
                    completion(AttributionResponse(status: .organic, result: nil), nil)
                    return
                case "error":
                    completion(nil, ASAToolsErrorCodes.errorResponseFromASATools.error(message: "attribution_status code is error"))
                    return
                default:
                    completion(nil, ASAToolsErrorCodes.errorResponseFromASATools.error(message: "attribution_status key unsupported: " + status))
                    return
                }
                
                guard let organizationId = responseJSON["organization_id"] as? Int,
                      let campaignId = responseJSON["campaign_id"] as? Int,
                      let adGroupId = responseJSON["ad_group_id"] as? Int,
                      let conversionTypeString = responseJSON["conversion_type"] as? String,
                      let conversionType = AttributionResult.ConversionType.from(string: conversionTypeString),
                      let region = responseJSON["region"] as? String,
                      let campaignName = responseJSON["campaign_name"] as? String,
                      let adGroupName = responseJSON["ad_group_name"] as? String
                else {
                    completion(nil, ASAToolsErrorCodes.errorResponseFromASATools.error(message: "one of required fields is missing: " + (String(data: data, encoding: .utf8) ?? "")))
                          return
                      }
                        
                let keywordId: Int? = responseJSON["keyword_id"] as? Int
                let creativeSetId: Int? = responseJSON["creative_set_id"] as? Int
                let keywordName: String? = responseJSON["keyword_name"] as? String
                
                let attributionResult = AttributionResult(
                    organizationId: organizationId,
                    campaignId: campaignId,
                    adGroupId: adGroupId,
                    keywordId: keywordId,
                    creativeSetId: creativeSetId,
                    conversionType: conversionType,
                    region: region,
                    campaignName: campaignName,
                    adGroupName: adGroupName,
                    keywordName: keywordName)

                self.attributionCompleted = true
                self.firstInstallOnDevice = false
                self.firstInstallOnAccount = false
                if self.initialUserID == nil {
                    self.initialUserID = self.userID
                }
                completion(AttributionResponse(status: .attributed, result: attributionResult), nil)
            }
        }.resume()
    }
    
    internal func osVersion() -> String {
        return "\(UIDevice.current.systemName)_\(UIDevice.current.systemVersion)"
    }
    
    internal func appVersion() -> String? {
        return (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
    }
}
