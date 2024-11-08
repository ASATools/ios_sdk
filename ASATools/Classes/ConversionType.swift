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
    
    @objc public enum ClaimType: Int {
        case click
        case view
        
        func description() -> String {
            switch self {
            case .click: return "click"
            case .view: return "view"
            }
        }
        
        static func from(string: String) -> ClaimType? {
            switch string {
            case "click": return .click
            case "view": return .view
            default:
                assert(false)
                return nil
            }
        }
    }
}
