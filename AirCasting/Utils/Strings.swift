// Created by Lunar on 23/06/2021.
//

import Foundation

struct Strings {
    enum Settings {
        static let title: String = "Settings"
        static let myAccount: String = "My Account"
        static let crowdMap: String = "Contribute to CrowdMap"
        static let crowdMapDescription: String = "Data contributed to the CrowdMap is publicly available at aircasting.org"
        static let backendSettings: String = "Backend settings"
        static let settingsHelp: String = "Help"
        static let hardwareDevelopers: String = "Hardware developers"
        static let about: String = "About AirCasting"
    }
    
    enum BackendSettings {
        static let backendSettings: String = "Backend settings"
        static let Ok: String = "OK"
        static let Cancel: String = "Cancel"
    }
    
    enum MyAccountSettings {
        static let title: String = "My account"
        static let logStatus: String = "You aren’t currently logged in"
        static let notLogged: String = "You aren’t currently logged in"
        static let createAccount: String = "Create an account"
        static let logIn: String = "Log In"
    }
    
    enum SignOutSettings {
        static let title: String = "My account"
        static let Logged: String = "You are currently logged in as admin@admin.com"
        static let signOut: String = "Sign Out"
    }
    
    enum sessionShare {
        static let title: String = "Share session"
        static let description: String = "Select a stream to share"
        static let emailDescription: String = "Or email a CSV file with your session data"
    }
    
    enum PowerABView {
        static let alertTitle: String = "Location alert"
        static let alertMessage: String = "Please go to settings and allow location first."
        static let alertConfirmation: String = "OK"
        static let alertSettings: String = "Settings"
        static let title: String = "Power on your AirBeam"
        static let messageText: String = "If using AirBeam 2, wait for the conncection indicator to change from red to green before continuing."
        static let continueButton: String = "Continue"
    }
    
    enum SelectDeviceView {
        static let alertTitle: String = "Location alert"
        static let alertMessage: String = "Please go to settings and allow location first."
        static let alertConfirmation: String = "OK"
        static let alertSettings: String = "Settings"
        static let title: String = "What device are you using to record this session?"
        static let bluetoothLabel_1: String = "Bluetooth device"
        static let bluetoothLabel_2: String = "for example AirBeam"
        static let micLabel_1: String = "Phone microphone"
        static let micLabel_2: String = "to measure sound level"
        static let chooseButton: String = "Choose"
    }
    
    enum TurnOnBluetoothView {
        static let title: String = "Turn on Bluetooth"
        static let messageText: String = "Turn on Bluetooth to enable your phone to connect to the AirBeam"
        static let continueButton: String = "Continue"
    }
}
