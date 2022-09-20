//
//  AppDelegate.swift
//  NewMap
//
//  Created by Pawel Gil on 28/09/2022.
//

import UIKit
import GoogleMaps

let GOOGLE_MAP_KEY = ""

@objc
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        GMSServices.provideAPIKey(GOOGLE_MAP_KEY)
        return true
    }
}
