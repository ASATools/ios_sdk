//
//  ASAAttributionResponse+descriptions.swift
//  ASAAttribution
//
//  Created by Vladislav Dugnist on 22.11.2021.
//

import Foundation

extension ASATools.AttributionResponse {
    @objc public func analyticsValues() -> [String: AnyHashable] {
        var values: [String: AnyHashable] = ["asa_attribution_status": self.status.description()]
        
        if let result = self.result {
            values["asa_campaign_name"] = result.campaignName
            values["asa_ad_group_name"] = result.adGroupName
            values["asa_keyword_name"] = result.keywordName
            values["asa_store_country"] = result.region
            
            if let creativeSet = result.creativeSetId {
                values["asa_creative_set_id"] = creativeSet.intValue
            }
        }
        
        return values
    }
}
