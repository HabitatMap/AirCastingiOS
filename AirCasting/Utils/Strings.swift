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
        static let Ok: String = "OK"
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
        static let Logged: String = "You are currently logged in as "
        static let signOut: String = "Sign Out"
    }
    
    struct SessionShare {
        static let title: String = "Share session"
        static let description: String = "Select a stream to share"
        static let emailDescription: String = "Or email a CSV file with your session data"
        static let alertTitle: String = "No Email app"
        static let alertDescription: String = "Please, install Apple Email app"
        static let alertButton: String = "Got it!"
        static let shareLinkButton: String = "Share link"
        static let shareFileButton: String = "Share file"
        static let checkboxDescription: String = "dB"
    }
    
    struct LoadingSession {
        static let title: String = "Your AirBeam is gathering data."
        static let description: String = "Your AirBeam is gathering data."
    }
    
    struct EmptyOnboarding {
        static let title: String = "Ready to get started?"
        static let description: String = "Record a new session to monitor your health & environment."
        static let newSession: String = "Record new session"
    }
}
