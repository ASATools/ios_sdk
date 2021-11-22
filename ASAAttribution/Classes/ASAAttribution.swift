//
//  ASAAttribution.swift
//  ASAAttribution
//
//  Created by Vladislav Dugnist on 16.11.2021.
//

import Foundation
import AdServices

public class ASAAttribution {
    public static let sharedInstance = ASAAttribution()
    private static let userIdDefaultsKey = "asa_attribution_user_id"
    private static let attributionCompletedDefaultsKey = "asa_attribution_completed"

    public var userID: String = {
        if let result = UserDefaults.standard.string(forKey: ASAAttribution.userIdDefaultsKey) {
            return result
        }
        
        let result = UUID().uuidString
        UserDefaults.standard.set(result, forKey: ASAAttribution.userIdDefaultsKey)
        return result
    }()
    
    public var isDebug: Bool = false
    
    private var attributionCompleted: Bool {
        get {
            return UserDefaults.standard.bool(forKey: ASAAttribution.attributionCompletedDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: ASAAttribution.attributionCompletedDefaultsKey)
        }
    }

    public func attribute(apiToken: String, completion: @escaping (_ response: AttributionResponse?, _ error: Error?) -> ()) {
        if self.attributionCompleted || self.isDebug {
            return
        }

        if #available(iOS 14.3, *) {
            let attributionToken: String

            do {
                try attributionToken = AAAttribution.attributionToken()
            } catch {
                completion(nil, ASAAttributionErrorCodes.errorGeneratingAttributionToken.error())
                return
            }
            
            self.attributeASAToken(attributionToken) { response, error in
                guard let response = response else {
                    completion(nil, error)
                    return
                }

                self.attributeASATokenResponse(attributionToken: attributionToken,
                                               apiToken: apiToken,
                                               asaResponse: response,
                                               completion: completion)
            }
        } else {
            completion(nil, ASAAttributionErrorCodes.unsupportedIOSVersion.error())
        }
    }
    
    private func attributeASAToken(_ token: String,
                        completion: @escaping (_ response: [String: AnyHashable]?, _ error: Error?) -> ()) {
        var request = URLRequest(url: URL(string:"https://api-adservices.apple.com/api/v1/")!)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(token.utf8)
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil,
                  let data = data,
                  let result = try? JSONSerialization.jsonObject(with: data,
                                                                 options: []) as? [String: AnyHashable] else {
                DispatchQueue.main.async {
                    completion(nil, ASAAttributionErrorCodes.errorResponseFromAppleAttribution.error())
                }
                return
            }

            DispatchQueue.main.async {
                completion(result, nil)
            }
        }.resume()
    }
    
    private func attributeASATokenResponse(attributionToken: String,
                                           apiToken: String,
                                           asaResponse: [String: AnyHashable],
                                           completion: @escaping (_ response: AttributionResponse?,
                                                                  _ error: Error?) -> ()) {
        var request = URLRequest(url: URL(string:"https://asaattribution.com/api/attribution")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let bodyJSON: [String: AnyHashable] = ["application_token": apiToken,
                                               "attribution_token": attributionToken,
                                               "user_id": self.userID,
                                               "asa_attribution_response": asaResponse]
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyJSON, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard error == nil,
                      let data = data,
                      let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []),
                      let responseJSON = responseJSON as? [String: AnyHashable] else {
                          completion(nil, ASAAttributionErrorCodes.errorResponseFromASAAttribution.error())
                          return
                      }
                
                if let status = responseJSON["status"] as? String, status == "debug_token_received" {
                    print("ASAAttribution: everything configured properly, but you've sent a debug token. You can now add\n\n#if DEBUG\n\tASAAttribution.shared.isDebug = true\n#endif\n\nbefore calling attribution to stop receiveing this message.")
                    completion(nil, ASAAttributionErrorCodes.debugAttributionTokenReceived.error())
                    return
                }
                
                guard let status = responseJSON["attribution_status"] as? String else {
                    completion(nil, ASAAttributionErrorCodes.errorResponseFromASAAttribution.error())
                    return
                }
                
                switch status {
                case "attributed": break
                case "organic":
                    self.attributionCompleted = true
                    completion(AttributionResponse(status: .organic, result: nil), nil)
                    return
                case "error":
                    completion(nil, ASAAttributionErrorCodes.errorResponseFromASAAttribution.error())
                    return
                default:
                    completion(nil, ASAAttributionErrorCodes.errorResponseFromASAAttribution.error())
                    return
                }
                
                guard let organizationId = responseJSON["organization_id"] as? Int,
                      let campaignId = responseJSON["campaign_id"] as? Int,
                      let adGroupId = responseJSON["ad_group_id"] as? Int,
                      let conversionTypeString = responseJSON["conversion_type"] as? String,
                      let conversionType = AttributionResult.ConversionType(rawValue: conversionTypeString),
                      let region = responseJSON["region"] as? String,
                      let campaignName = responseJSON["campaign_name"] as? String,
                      let adGroupName = responseJSON["ad_group_name"] as? String
                else {
                          completion(nil, ASAAttributionErrorCodes.errorResponseFromASAAttribution.error())
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
