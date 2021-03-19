//
//  UserDefaults+Preferences.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import Foundation


extension UserDefaults {

    static var AUTH_TOKEN_KEY = "auth_token"
    
    @UserDefault(key: AUTH_TOKEN_KEY, defaultValue: nil)
    static var authToken: String?
        
}





@propertyWrapper
struct UserDefault<Value> {
    let key: String
    let defaultValue: Value
    var container: UserDefaults = .standard

    var wrappedValue: Value {
        get {
            return container.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            container.set(newValue, forKey: key)
        }
    }
}
