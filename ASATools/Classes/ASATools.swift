//
//  ASAAttribution.swift
//  ASAAttribution
//
//  Created by Vladislav Dugnist on 16.11.2021.
//

import Foundation
import AdServices

public class ASATools: NSObject {
    @objc public static let instance = ASATools()
    public static let libVersion = "1.2.2"
    
    private static let userIdDefaultsKey = "asa_attribution_user_id"
    private static let attributionCompletedDefaultsKey = "asa_attribution_completed"
    private static let installDateDefaultsKey = "asa_attribution_install_date"
    static let purchaseEvents = "asa_attribution_purchase_events"
    
    // 3 attempts with 5 seconds delay as in documentation for AAAttribution.attributionToken()
    private var appleAttributionRequestsAttempts: Int = 3
    private let appleAttributionRequestDelay: TimeInterval = 5.0
    var isSyncingPurchases: Bool = false
    var apiToken: String? = nil
    
    public override init() {
        super.init()
        
        let purchasesMigratedKey = "asaattribution_purchases_migrated"
        if UserDefaults.standard.bool(forKey: purchasesMigratedKey) == false {
            UserDefaults.standard.removeObject(forKey: ASATools.purchaseEvents)
            UserDefaults.standard.set(true, forKey: purchasesMigratedKey)
        }

        self.subscribeToPaymentQueue()
    }

    @objc public var userID: String = {
        if let result = UserDefaults.standard.string(forKey: ASATools.userIdDefaultsKey) {
            return result
        }
        
        let result = UUID().uuidString
        UserDefaults.standard.set(result, forKey: ASATools.userIdDefaultsKey)
        return result
    }()
    
    private var installDate: TimeInterval = {
        if let date = UserDefaults.standard.object(forKey: ASATools.installDateDefaultsKey) as? Date  {
            return date.timeIntervalSince1970
        }
        
        let date = Date()
        UserDefaults.standard.set(date, forKey: ASATools.installDateDefaultsKey)
        return date.timeIntervalSince1970
    }()
    
    public var isDebug: Bool = false
    
    private var attributionCompleted: Bool {
        get {
            return UserDefaults.standard.bool(forKey: ASATools.attributionCompletedDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: ASATools.attributionCompletedDefaultsKey)
        }
    }

    @objc public func attribute(apiToken: String,
                          completion: @escaping (_ response: AttributionResponse?, _ error: Error?) -> ()) {
        self.apiToken = apiToken
        self.syncPurchasedEvents()

        if self.attributionCompleted || self.isDebug {
            return
        }
        
        let installDate = self.installDate

        if #available(iOS 14.3, *) {
            DispatchQueue.global().async {
                let attributionToken: String

                do {
                    try attributionToken = AAAttribution.attributionToken()
                } catch {
                    DispatchQueue.main.async {
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
        } else {
            completion(nil, ASAToolsErrorCodes.unsupportedIOSVersion.error())
        }
    }
    
    private func attributeASAToken(_ token: String,
                        completion: @escaping (_ response: [String: AnyHashable]?, _ error: Error?) -> ()) {
        var request = URLRequest(url: URL(string:"https://api-adservices.apple.com/api/v1/")!)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(token.utf8)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
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

                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + self.appleAttributionRequestDelay) {
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
    
    public func attributeASATokenResponse(attributionToken: String,
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
                                               "lib_version": ASATools.libVersion,
                                               "user_id": self.userID,
                                               "install_date": installDate]
        bodyJSON["asa_attribution_response"] = asaResponse

        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyJSON, options: [])
        
        URLSession.shared.dataTask(with: request) { optionalData, response, error in
            DispatchQueue.main.async {
                guard error == nil,
                      let data = optionalData,
                      let responseJSON = (try? JSONSerialization.jsonObject(with: data, options: []))
                        as? [String: AnyHashable] else {
                          completion(nil, ASAToolsErrorCodes.errorResponseFromASAAttribution.error(message: "response is empty or not a json: \(String(data: optionalData ?? Data(), encoding: .utf8) ?? "none") statusCode: \((response as? HTTPURLResponse)?.statusCode ?? 0)"))
                          return
                      }
                
                if let status = responseJSON["status"] as? String, status == "debug_token_received" {
                    print("ASAAttribution: everything configured properly, but you've sent a debug token. You can now add\n\n#if DEBUG\n\tASAAttribution.shared.isDebug = true\n#endif\n\nbefore calling attribution to stop receiveing this message.")
                    completion(nil, ASAToolsErrorCodes.debugAttributionTokenReceived.error())
                    return
                }
                
                guard let status = responseJSON["attribution_status"] as? String else {
                    completion(nil, ASAToolsErrorCodes.errorResponseFromASAAttribution.error(message: "attribution status is empty"))
                    return
                }
                
                switch status {
                case "attributed": break
                case "organic":
                    self.attributionCompleted = true
                    completion(AttributionResponse(status: .organic, result: nil), nil)
                    return
                case "error":
                    completion(nil, ASAToolsErrorCodes.errorResponseFromASAAttribution.error(message: "attribution_status code is error"))
                    return
                default:
                    completion(nil, ASAToolsErrorCodes.errorResponseFromASAAttribution.error(message: "attribution_status key unsupported: " + status))
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
                    completion(nil, ASAToolsErrorCodes.errorResponseFromASAAttribution.error(message: "one of required fields is missing: " + (String(data: data, encoding: .utf8) ?? "")))
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
                completion(AttributionResponse(status: .attributed, result: attributionResult), nil)
            }
        }.resume()
    }
}
