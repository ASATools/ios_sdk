//
//  ASAAttribution+purchaseEvents.swift
//  ASAAttribution
//
//  Created by Vladislav Dugnist on 15.12.2021.
//

import Foundation
import StoreKit

extension ASATools: SKPaymentTransactionObserver {
    
    func subscribeToPaymentQueue() {
        SKPaymentQueue.default().add(self)
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue,
                             updatedTransactions transactions: [SKPaymentTransaction]) {
        DispatchQueue.main.async {
            transactions.filter { (tr) -> Bool in
                return tr.transactionState == .purchased
            }.forEach { transaction in
                guard let transactionId = transaction.transactionIdentifier,
                      let transactionDate = transaction.transactionDate else {
                    return
                }
                self.savePurchasedTransactionWith(transactionId: transactionId,
                                                  productIdentifier: transaction.payment.productIdentifier,
                                                  transactionDate: transactionDate)
                self.syncPurchasedEvents()
            }
        }
    }
    
    private func savePurchasedTransactionWith(transactionId: String, productIdentifier: String, transactionDate: Date) {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
                  return
              }
        var events = self.getPurchaseEvents() ?? []
        guard !events.contains(where: { event in
            return event.transactionId == transactionId
        }) else {
            return
        }

        let purchaseEvent = ASAToolsPurchaseEvent(purchaseDate: transactionDate,
                                                        transactionId: transactionId,
                                                        productId: productIdentifier,
                                                        receipt: receiptData.base64EncodedString())
        events.append(purchaseEvent)
        self.setPurchaseEvents(events)
    }
    
    func syncPurchasedEvents() {
        if self.isSyncingPurchases {
            return
        }
        
        guard let apiToken = self.apiToken else {
            return
        }
        
        guard let purchases = self.getPurchaseEvents(),
              let purchase = purchases.first(where: { event in
                  !event.synced
              }) else {
            return
        }

        self.isSyncingPurchases = true
        
        var parameters = purchase.dictionaryRepresentation()
        parameters["user_id"] = self.userID
        parameters["lib_version"] = ASATools.libVersion
        parameters["application_token"] = apiToken
        
        var request = URLRequest(url: URL(string: "https://asa.tools/api/purchase_event")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isSyncingPurchases = false
                
                guard let data = data,
                      let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject],
                      let status = responseJSON["status"] as? String,
                      status == "ok" else {
                          return
                      }
                
                var purchases = self.getPurchaseEvents()!
                if let index = purchases.firstIndex(of: purchase) {
                    purchases[index].synced = true
                }
                self.setPurchaseEvents(purchases)
                self.syncPurchasedEvents()
            }
        }.resume()
    }
    
    private func getPurchaseEvents() -> [ASAToolsPurchaseEvent]? {
        guard let eventsData = UserDefaults.standard.data(forKey: ASATools.purchaseEvents) else {
            return nil
        }
        
        guard let events = try? JSONDecoder().decode([ASAToolsPurchaseEvent].self, from: eventsData) else {
            return nil
        }
        
        return events
    }
    
    private func setPurchaseEvents(_ events: [ASAToolsPurchaseEvent]) {
        guard let data = try? JSONEncoder().encode(events) else {
            return
        }
        
        UserDefaults.standard.set(data, forKey: ASATools.purchaseEvents)
    }
}
