//
//  ASAAttributionResponse.swift
//  ASAAttribution
//
//  Created by Vladislav Dugnist on 16.11.2021.
//

import Foundation

extension ASAAttribution {
    public struct AttributionResponse {
        public let status: AttributionStatus
        public let result: AttributionResult?
        
        public func analyticsValues() -> [String: AnyHashable] {
            var values: [String: AnyHashable] = ["asa_attribution_status": self.status.description()]
            
            if let result = self.result {
                values["asa_campaign_name"] = result.campaignName
                values["asa_ad_group_name"] = result.adGroupName
                values["asa_keyword_name"] = result.keywordName
                values["asa_conversion_type"] = result.conversionType.description()
                values["asa_creative_set_id"] = result.creativeSetId
            }
            
            return values
        }
    }
    
    public enum AttributionStatus {
        case attributed
        case organic
        
        func description() -> String {
            switch self {
            case .attributed: return "attributed"
            case .organic: return "organic"
            }
        }
    }
    
    public struct AttributionResult {
        public enum ConversionType: String {
            case download = "Download"
            case redownload = "Redownload"
            
            func description() -> String {
                return self.rawValue.lowercased()
            }
        }
        
        let organizationId: Int
        let campaignId: Int
        let adGroupId: Int
        let keywordId: Int? // may be nil for discovery campaigns
        let creativeSetId: Int? // may be nil if you are not using custom creative set
        let conversionType: ConversionType
        let region: String
        let campaignName: String
        let adGroupName: String
        let keywordName: String? // may be nil for discovery campaigns
    }
}
