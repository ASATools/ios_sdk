//
//  ASAAttributionResponse.swift
//  ASAAttribution
//
//  Created by Vladislav Dugnist on 16.11.2021.
//

import Foundation

extension ASATools {
    @objc public class AttributionResponse: NSObject {
        @objc public let status: AttributionStatus
        @objc public let result: AttributionResult?
        
        init(status: AttributionStatus, result: AttributionResult?) {
            self.status = status
            self.result = result
            super.init()
        }
    }
    
    @objc public enum AttributionStatus: Int {
        case attributed
        case organic
        
        public func description() -> String {
            switch self {
            case .attributed: return "attributed"
            case .organic: return "organic"
            }
        }
    }
    
    @objc public class AttributionResult: NSObject {
        @objc public let organizationId: Int
        @objc public let campaignId: Int
        @objc public let adGroupId: Int
        @objc public let keywordId: NSNumber? // may be nil for discovery campaigns
        @objc public let creativeSetId: NSNumber? // may be nil if you are not using custom creative set
        @objc public let conversionType: ConversionType
        @objc public let region: String
        @objc public let campaignName: String
        @objc public let adGroupName: String
        @objc public let keywordName: String? // may be nil for discovery campaigns
        
        init(organizationId: Int,
                campaignId: Int,
                adGroupId: Int,
                keywordId: Int?,
                creativeSetId: Int?,
                conversionType: ConversionType,
                region: String,
                campaignName: String,
                adGroupName: String,
                keywordName: String?) {
            self.organizationId = organizationId
            self.campaignId = campaignId
            self.adGroupId = adGroupId
            self.keywordId = keywordId == nil ? nil : NSNumber(value: keywordId!)
            self.creativeSetId = creativeSetId == nil ? nil : NSNumber(value: creativeSetId!)
            self.conversionType = conversionType
            self.region = region
            self.campaignName = campaignName
            self.adGroupName = adGroupName
            self.keywordName = keywordName
            super.init()
        }
    }
}
