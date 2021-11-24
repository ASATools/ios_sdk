//
//  ASAAttributionResponse+descriptions.swift
//  ASAAttribution
//
//  Created by Vladislav Dugnist on 22.11.2021.
//

import Foundation

extension ASAAttribution.AttributionResponse {
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

extension ASAAttribution.AttributionStatus {
    public func description() -> String {
        switch self {
        case .attributed: return "attributed"
        case .organic: return "organic"
        }
    }
}
