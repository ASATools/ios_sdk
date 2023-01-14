//
//  ASAAttributionPurchaseEvent.swift
//  ASAAttribution
//
//  Created by Vladislav Dugnist on 15.12.2021.
//

import Foundation

struct ASAToolsPurchaseEvent: Equatable, Codable {
    let purchaseDate: Date
    let transactionId: String
    let productId: String
    let storeKit1Receipt: String?
    let storeKit2JSON: String?
    let countryCode: String?
    var synced: Bool = false
    
    func dictionaryRepresentation() -> [String: AnyHashable] {
        var result: Dictionary<String, AnyHashable> = [
            "transaction_date": self.purchaseDate.timeIntervalSince1970,
            "product_id": self.productId
        ]

        result["product_receipt"] = self.storeKit1Receipt
        result["store_kit_2_json"] = self.storeKit2JSON
        result["country_code"] = self.countryCode

        return result
    }
}
