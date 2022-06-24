// Created by Lunar on 18/04/2021.
//

import Foundation

final class KeychainStorage {
    public enum KeychainStorageError: Swift.Error, Equatable {
        case unexpectedData
        case invalidTypeData(Data)
        case unhandledError(status: OSStatus)
    }
    
    enum UserData: String {
        case username = "username"
        case email = "email"
    }
    
    let service: String
    let accessGroup: String?
    
    /// - SeeAlso: kSecAttrAccessGroup
    /// - Parameters:
    ///   - service: The name of the keychain service. By default it would be the Bundle ID of the App - kSecAttrService
    ///   - accessGroup: The access group an item is in. - kSecAttrAccessGroup
    public init(service: String, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }
    
    public func data(forKey key: String) throws -> Data? {
        let query = makeRetrieveQuery(for: key)
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        switch status {
        case errSecItemNotFound:
            return nil
        case noErr:
            guard let value = queryResult.flatMap({ $0 as? [String: AnyObject] }).flatMap({ $0[kSecValueData as String] as? Data }) else {
                throw KeychainStorageError.unexpectedData
            }
            return value
        default:
            throw KeychainStorageError.unhandledError(status: status)
        }
    }
    
    public func setString(_ value: String, forKey key: String) throws {
        try setValue(value: Data(value.utf8), forKey: key)
    }
    
    public func setValue(value: Data, forKey key: String) throws {
        if (try data(forKey: key)) != nil {
            try update(for: key, value: value)
        } else {
            try create(for: key, value: value)
        }
    }
    
    public func removeValue(forKey: String) throws {
        let query = makeQuery(for: forKey)
        let status = SecItemDelete(query as CFDictionary)
        guard status == noErr || status == errSecItemNotFound else {
            throw KeychainStorageError.unhandledError(status: status)
        }
    }
    
    public func string(forKey key: String) throws -> String? {
        guard let data: Data = try data(forKey: key) else {
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainStorageError.invalidTypeData(data)
        }
        return string
    }
    
    public func getProfileData(_ from: UserData) -> String {
        if let value = try! (KeychainStorage(service: service).data(forKey: "UserProfileKey")) {
            do {
                let json = try JSONSerialization.jsonObject(with: value, options: []) as? [String : Any]
                return json?[from.rawValue] as! String
            } catch {
                return "[error fetching]"
            }
        } else {
            return "[error fetching]"
        }
    }
    
    private func update(for key: String, value: Data) throws {
        let attributesToUpdate: [CFString: AnyObject] = [kSecValueData: value as AnyObject]
        let status = SecItemUpdate(makeQuery(for: key) as CFDictionary, attributesToUpdate as CFDictionary)
        guard status == noErr else {
            throw KeychainStorageError.unhandledError(status: status)
        }
    }
    
    private func create(for key: String, value: Data) throws {
        var newItem = makeQuery(for: key)
        newItem[kSecValueData] = value as AnyObject?
        newItem[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(newItem as CFDictionary, nil)
        guard status == noErr else {
            throw KeychainStorageError.unhandledError(status: status)
        }
    }
    
    private func makeRetrieveQuery(for key: String) -> [CFString: AnyObject] {
        var query = makeQuery(for: key)
        query[kSecMatchLimit] = kSecMatchLimitOne
        query[kSecReturnAttributes] = kCFBooleanTrue
        query[kSecReturnData] = kCFBooleanTrue
        return query
    }
    
    private func makeQuery(for key: String) -> [CFString: AnyObject] {
        var query: [CFString: AnyObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service as AnyObject,
            kSecAttrAccount: key as AnyObject
        ]
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup] = accessGroup as AnyObject
        }
        return query
    }
}
