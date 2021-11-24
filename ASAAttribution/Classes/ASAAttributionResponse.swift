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
        public let organizationId: Int
        public let campaignId: Int
        public let adGroupId: Int
        public let keywordId: Int? // may be nil for discovery campaigns
        public let creativeSetId: Int? // may be nil if you are not using custom creative set
        public let conversionType: ConversionType
        public let region: String
        public let campaignName: String
        public let adGroupName: String
        public let keywordName: String? // may be nil for discovery campaigns
    }
}
