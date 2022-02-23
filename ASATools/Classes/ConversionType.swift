//
//  ConversionType.swift
//  ASAAttribution
//
//  Created by Vladislav Dugnist on 22.11.2021.
//

import Foundation

extension ASATools.AttributionResult {
    @objc public enum ConversionType: Int {
        case download
        case redownload
        
        func description() -> String {
            switch self {
            case .download: return "download"
            case .redownload: return "redownload"
            }
        }
        
        static func from(string: String) -> ConversionType? {
            switch string {
            case "Download": return .download
            case "Redownload": return .redownload
            default:
                assert(false)
                return nil
            }
        }
    }
}
