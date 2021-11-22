//
//  ConversionType.swift
//  ASAAttribution
//
//  Created by Vladislav Dugnist on 22.11.2021.
//

import Foundation

extension ASAAttribution.AttributionResult {
    public enum ConversionType: String {
        case download = "Download"
        case redownload = "Redownload"
        
        func description() -> String {
            return self.rawValue.lowercased()
        }
    }
}
