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
    }
    
    public enum AttributionStatus {
        case attributed
        case organic        
    }
    
    public struct AttributionResult {        
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
