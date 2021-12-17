//
//  ASAAttributionPurchaseEvent.swift
//  ASAAttribution
//
//  Created by Vladislav Dugnist on 15.12.2021.
//

import Foundation

struct ASAAttributionPurchaseEvent: Equatable, Codable {
    let purchaseDate: Date
    let productId: String
    let receipt: String
    
    func dictionaryRepresentation() -> [String: AnyHashable] {
        return [
            "purchase_date": self.purchaseDate.timeIntervalSince1970,
            "product_id": self.productId,
            "product_receipt": self.receipt
        ]
    }
}
