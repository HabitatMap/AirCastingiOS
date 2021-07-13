// Created by Lunar on 23/06/2021.
//

import Foundation

struct Strings {
    struct Settings {
        static let title: String = "Settings"
        static let myAccount: String = "My Account"
        static let crowdMap: String = "Contribute to CrowdMap"
        static let crowdMapDescription: String = "Data contributed to the CrowdMap is publicly available at aircasting.org"
        static let backendSettings: String = "Backend settings"
        static let settingsHelp: String = "Help"
        static let hardwareDevelopers: String = "Hardware developers"
        static let about: String = "About AirCasting"
    }
    
    struct BackendSettings {
        static let backendSettings: String = "Backend settings"
        static let Ok: String = "Ok"
        static let Cancel: String = "Cancel"
    }
    
    struct MyAccountSettings {
        static let title: String = "My account"
        static let logStatus: String = "You aren’t currently logged in"
        static let notLogged: String = "You aren’t currently logged in"
        static let createAccount: String = "Create an account"
        static let logIn: String = "Log In"
    }
    
    struct SignOutSettings {
        static let title: String = "My account"
        static let Logged: String = "You are currently logged in as admin@admin.com"
        static let signOut: String = "Sign Out"
    }
    
    struct sessionShare {
        static let title: String = "Share session"
        static let description: String = "Select a stream to share"
        static let emailDescription: String = "Or email a CSV file with your session data"
    }
    
    struct EditSession {
        static let title: String = "Edit session details"
        static let namePlaceholder: String = "Session name"
        static let tagPlaceholder: String = "Select a stream to share"
        static let buttonAccept: String = "Accept"
    }
}
