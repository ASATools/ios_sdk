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
    let receipt: String
    var synced: Bool = false
    
    func dictionaryRepresentation() -> [String: AnyHashable] {
        return [
            "transaction_date": self.purchaseDate.timeIntervalSince1970,
            "product_id": self.productId,
            "product_receipt": self.receipt
        ]
    }
}
