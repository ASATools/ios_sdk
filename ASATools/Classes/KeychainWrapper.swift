//
//  KeychainWrapper.swift
//  ASATools
//
//  Created by Vladislav Dugnist on 14.04.2022.
//

import Foundation

internal class KeychainWrapper {
    static func storeBool(_ value: Bool, forKey: String, syncInKeychain: Bool = false) {
        let stringValue = (value == true) ? "true" : "false"
        self.storeString(stringValue, forKey: forKey, syncInKeychain: syncInKeychain)
    }

    static func boolValueFor(key: String, syncInKeycnain: Bool = false) -> Bool? {
        let stringValue = self.stringValueFor(key: key, syncInKeycnain: syncInKeycnain)

        switch stringValue {
        case "true": return true
        case "false": return false
        default: return nil
        }
    }

    static func storeString(_ value: String, forKey: String, syncInKeychain: Bool = false) {
        self.storeValue(value.data(using: .utf8)!, forKey: forKey, syncInKeychain: syncInKeychain)
    }

    static func stringValueFor(key: String, syncInKeycnain: Bool = false) -> String? {
        guard let data = self.valueForKey(key, syncInKeychain: syncInKeycnain) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private static func storeValue(_ value: Data, forKey: String, syncInKeychain: Bool) {
        var query = self.queryFor(key: forKey, syncInKeychain: syncInKeychain)

        query[kSecValueData as String] = value as AnyObject

        var status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            status = SecItemUpdate(query as CFDictionary, [kSecValueData: value] as CFDictionary)
        } else if status == errSecItemNotFound {
            status = SecItemAdd(query as CFDictionary, nil)
        }

        assert(status == errSecSuccess)
    }

    private static func valueForKey(_ key: String, syncInKeychain: Bool = false) -> Data? {
        var query = self.queryFor(key: key, syncInKeychain: syncInKeychain)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let password = result as? Data else {
            return nil
        }

        return password
    }

    private static func queryFor(key: String, syncInKeychain: Bool) -> [String: AnyObject] {
        let bundle = "asatools_" + (Bundle.main.bundleIdentifier ?? "")
        var result: [String: AnyObject] = [
            kSecAttrService as String: bundle as AnyObject,
            kSecAttrAccount as String: key as AnyObject,
            kSecClass as String: kSecClassGenericPassword
        ]

        if syncInKeychain {
            result[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }

        return result
    }
}
