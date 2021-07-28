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
        static let Logged: String = "You are currently logged in as "
        static let signOut: String = "Sign Out"
    }

    enum sessionShare {}
    
    enum ForgotPassword {
        static let title = "Forgot Password"
        static let actionTitle = "OK"
        static let cancelTitle = "Cancel"
        static let emailInputTitle = "email or username"
        static let newPasswordSuccessMessage = "Email was sent. Please check your inbox for the details."
        static let newPasswordSuccessTitle = "Email response"
        static let newPasswordFailureMessage = "Something went wrong, please try again"
        static let newPasswordFailureTitle = "Email response"
        static let alertAction = "OK"
    }
    
    enum SignInView {
        static let title_1 = "Sign in"
        static let title_2 = "to record and map your environment"
        static let usernameField = "Profile name"
        static let passwordField = "Password"
        static let forgotPasswordButton = "Forgot password?"
        static let signInButton = "Sign in"
        static let signUpButton_1 = "First time here? "
        static let signUpButton_2 = "Create an account"
        static let alertTitle = "Login Error"
        static let alertComment = "Login Error alert title"
        static let dismissButton = "OK"
        static let InvalidCredentialText = "The profile name or password is incorrect. Please try again. "
        static let noConnectionTitle = "No Internet Connection"
        static let noConnectionText = "Please make sure your device is connected to the internet."
    }
    
    enum SessionShare {
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
    
    enum LoadingSession {
        static let title: String = "Your AirBeam is gathering data."
        static let description: String = "Your AirBeam is gathering data."
    }

    enum WifiPopupView {
        static let wifiPlaceholder: String = "Wi-Fi name"
        static let passwordPlaceholder: String = "Password"
        static let connectButton: String = "Connect"
        static let cancelButton: String = "Cancel"
        static let passwordTitle: String = "Provide name and password for the Wi-Fi network"
        static let nameAndPasswordTitle_1: String = "Provide password for"
        static let nameAndPasswordTitle_2: String = "network"
        static let differentNetwork: String = "I'd like to connect with a different Wi-Fi network."
    }

    enum OnboardingGetStarted {
        static let description: String = "record and map measurements from health and environmental monitoring devices"
        static let getStarted: String = "Get started"
    }
    
    enum OnboardingNearAir {
        static let title: String = "How’s the air \nnear you?"
        static let description: String = "Find and follow a fixed air quality monitor near you and know how clean or polluted your air is right now."
        static let continueButton: String = "How’s the air \nnear you?"
    }
    
    enum OnboardingAirBeam {
        static let title: String = "Measure and map \nyour exposure \nto air pollution"
        static let description: String = "Connect AirBeam to measure air quality humidity, and temperature."
        static let continueButton: String = "Continue"
        static let sheetButton: String = "Learn More"
    }
    
    enum OnboardingAirBeamSheet {
        static let sheetTitle: String = "How AirBeam works?"
        static let sheetDescription_1: String = "Your AirBeam is gathering data."
        static let sheetDescription_2: String = " mobile "
        static let sheetDescription_3: String = "mode, the AirBeam captures personal exposures.\n\n\nIn"
        static let sheetDescription_4: String = " fixed "
        static let sheetDescription_5: String = "mode, it can be installed indoors or outdoors to keep tabs on pollution levels in your home, office, backyard, or neighborhood 24/7."
    }
    
    enum OnboardingPrivacy {
        static let title: String = "Your privacy"
        static let description: String = "Have a look at how we store and protect Your data and accept our privacy policy and terms of service before continuing."
        static let continueButton: String = "Accept"
        static let sheetButton: String = "Learn More"
    }
    
    enum OnboardingPrivacySheet {
        static let title: String = "Our privacy policy"
        static let description: String = """
        HabitatMap protects the personal data of AirCasting mobile application users, and fulfills conditions deriving from the law, especially from the Regulation (EU) 2016/679 of the European Parliament and of the Council of 27 April 2016 on the protection of natural persons with regard to the processing of personal data and on the free movement of such data, and repealing Directive 95/46/EC (GDPR). HabitatMap protects the security of the data of AirCasting app users using appropriate technical, logistical, administrative, and physical protection measures. AirCasting ensures that its employees and contractors are given training in protection of personal data.
            
        This privacy policy sets out the rules for HabitatMap’s processing of your data, including personal data, in relation to your use of the AirCasting mobile application.
        """
    }

    enum EmptyOnboarding {
        static let title: String = "Ready to get started?"
        static let description: String = "Record a new session to monitor your health & environment."
        static let newSession: String = "Record new session"
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
    
    enum TurnOnLocationView {
        static let title: String = "Turn on location services"
        static let messageText: String = "To map your measurements, turn on location services."
        static let continueButton: String = "Turn on"
    }
    
    enum DeleteSession {
        static let title: String = "Delete this session"
        static let description: String = "Which stream would you like to delete?"
        static let continueButton: String = "Delete streams"
        static let cancelButton: String = "Cancel"
    }
    
    enum EditSession {
        static let title: String = "Edit session details"
        static let namePlaceholder: String = "Session name"
        static let tagPlaceholder: String = "Select a stream to share"
        static let buttonAccept: String = "Accept"
    }
    
    enum SessionHeaderView {
        static let measurementsMicText: String = "Most recent measurement:"
        static let stopButton: String = "Stop recording"
        static let resumeButton: String = "Resume recording"
        static let editButton: String = "Edit recording"
        static let shareButton: String = "Share session"
        static let deleteButton: String = "Delete session"
        static let alertTitle: String = "No internet connection"
        static let alertMessage: String = "You need to have internet connection to edit session data"
        static let confirmAlert: String = "Got it!"
    }
    
    enum NetworkChecker {
        static let satisfiedPathText: String = "Current devise has an network connection"
        static let failurePathText: String = "Current devise DOES NOT have an network connection"
    }
    
    enum ChooseSessionTypeView {
        static let title: String = "Let's begin"
        static let message: String = "How would you like to add your session?"
        static let recordNew: String = "Record a new session"
        static let moreInfo: String = "more info"
        static let fixedLabel_1: String = "Fixed session"
        static let fixedLabel_2: String = "for measuring in one place"
        static let mobileLabel_1: String = "Mobile session"
        static let mobileLabel_2: String = "for moving around"
    }
    
    enum MoreInfoPopupView {
        static let text_1: String = "Session types"
        static let text_2: String = "If you plan on moving around with the AirBeam3 while recording air quality measurement, configure the AirBeam to record a mobile session. When recording a mobile AirCasting session, measurements are created, timestamped, and geolocated once per second."
        static let text_3: String = "If you plan to leave the AirBeam3 indoors or hang it outside then configure it to record a fixed session. When recording fixed AirCasting sessions, measurements are created and timestamped once per minute, and geocoordinates are fixed to a set location."
    }
    
    enum SelectPeripheralView {
        static let airBeams: String = "AirBeams"
        static let otherDevices: String = "Other devices"
        static let title: String = "Choose the device you'd like to record with"
        static let refresh: String = "Don't see a device? Refresh scanning."
        static let connect: String = "Connect"
    }
    
    enum ConnectingABView {
        static let title: String = "Connecting"
        static let message: String = "This should take less than 10 seconds."
        static let connect: String = "Connect"
    }
    
    enum ABConnectedView {
        static let title: String = "AirBeam connected"
        static let message: String = "Your AirBeam is connected to your phone and ready to take some measurements."
        static let continueButton: String = "Continue"
    }
    
    enum CreateSessionDetailsView {
        static let wifiAlertTitle: String = "Wi-Fi credentials are empty "
        static let wifiAlertMessage: String = "Do you want to pop up Wi-Fi screen?"
        static let primaryWifiButton: String = "Show Wi-fi screen"
        static let cancelButton: String = "Cancel"
        static let continueButton: String = "Continue"
        static let title: String = "New session details"
        static let placementPicker_1: String = "Continue"
        static let placementPicker_2: String = "Continue"
        static let placementPicker_3: String = "Continue"
        static let transmissionPicker: String = "Data transmission:"
        static let callularText: String = "Cellular"
        static let wifiText: String = "Wi-Fi"
    }
    
    enum ConfirmCreatingSessionView {
        static let connectWithAlertText: String = "Failure"
        static let gotItButton: String = "Got it!"
        static let connectView_1: String = "Are you ready?"
        static let connectView_2: String = "Your "
        static let connectView_3: String = " session "
        static let connectView_4: String = " is ready to start gathering data."
        static let connectView_5: String = "Move to your starting location, confirm your location is accurate on the map, then press the start recording button below."
        static let startRecording: String = "Start recording"
    }
}
