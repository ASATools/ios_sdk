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

        if #available(iOS 15, *) {
            self.storeKit2ListenerTask = Task.detached {
                for await veritificationResult in Transaction.updates {
                    self.handleStoreKit2Result(verificationResult: veritificationResult)
                }
            }
        }
    }

    @available(iOS 15, *)
    private func handleStoreKit2Result(verificationResult: VerificationResult<Transaction>) {
        switch verificationResult {
        case let .verified(verifiedTransaction):
            if verifiedTransaction.ownershipType != .purchased {
                return
            }

            if #available(iOS 16, *) {
                if verifiedTransaction.environment != .production {
                    return
                }
            }

            guard let jsonString = String(data: verifiedTransaction.jsonRepresentation,
                                          encoding: .utf8) else {
                return
            }

            let countryCode: String? = SKPaymentQueue.default().storefront?.countryCode

            DispatchQueue.main.async {
                self.savePurchasedTransactionWith(
                    transactionId: String(verifiedTransaction.originalID),
                    productIdentifier: verifiedTransaction.productID,
                    transactionDate: verifiedTransaction.originalPurchaseDate,
                    countryCode: countryCode,
                    receiptData: nil,
                    storeKit2Receipt: jsonString
                )
                self.syncPurchasedEvents()
            }
        default: break
        }
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
                guard let receiptURL = Bundle.main.appStoreReceiptURL,
                      let receiptData = try? Data(contentsOf: receiptURL) else {
                          return
                      }
                
                let countryCode: String? = {
                    if #available(iOS 13, *) {
                        return queue.storefront?.countryCode
                    } else {
                        return nil
                    }
                }()
                
                self.savePurchasedTransactionWith(transactionId: transactionId,
                                                  productIdentifier: transaction.payment.productIdentifier,
                                                  transactionDate: transactionDate,
                                                  countryCode: countryCode,
                                                  receiptData: receiptData,
                                                  storeKit2Receipt: nil)
                self.syncPurchasedEvents()
            }
        }
    }

    private func savePurchasedTransactionWith(transactionId: String,
                                              productIdentifier: String,
                                              transactionDate: Date,
                                              countryCode: String?,
                                              receiptData: Data?,
                                              storeKit2Receipt: String?) {
        var events = self.getPurchaseEvents() ?? []
        guard !events.contains(where: { event in
            return event.transactionId == transactionId
        }) else {
            return
        }

        let purchaseEvent = ASAToolsPurchaseEvent(purchaseDate: transactionDate,
                                                  transactionId: transactionId,
                                                  productId: productIdentifier,
                                                  storeKit1Receipt: receiptData?.base64EncodedString(),
                                                  storeKit2JSON: storeKit2Receipt,
                                                  countryCode: countryCode)
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
