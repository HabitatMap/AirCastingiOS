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

    struct WifiPopupView {
        static let wifiPlaceholder: String = "Wi-Fi name"
        static let passwordPlaceholder: String = "Password"
        static let connectButton: String = "Connect"
        static let cancelButton: String = "Cancel"
        static let passwordTitle: String = "Provide name and password for the Wi-Fi network"
        static let nameAndPasswordTitle_1: String = "Provide password for"
        static let nameAndPasswordTitle_2: String = "network"
        static let differentNetwork: String = "I'd like to connect with a different Wi-Fi network."
    }

    struct OnboardingGetStarted {
        static let description: String = "record and map measurements from health and environmental monitoring devices"
        static let getStarted: String = "Get started"
    }
    
    struct OnboardingNearAir {
        static let title: String = "How’s the air \nnear you?"
        static let description: String = "Find and follow a fixed air quality monitor near you and know how clean or polluted your air is right now."
        static let continueButton: String = "How’s the air \nnear you?"
    }
    
    struct OnboardingAirBeam {
        static let title: String = "Measure and map \nyour exposure \nto air pollution"
        static let description: String = "Connect AirBeam to measure air quality humidity, and temperature."
        static let continueButton: String = "Continue"
        static let sheetButton: String = "Learn More"
    }
    
    struct OnboardingAirBeamSheet {
        static let sheetTitle: String = "How AirBeam works?"
        static let sheetDescription_1: String = "Your AirBeam is gathering data."
        static let sheetDescription_2: String = " mobile "
        static let sheetDescription_3: String = "mode, the AirBeam captures personal exposures.\n\n\nIn"
        static let sheetDescription_4: String = " fixed "
        static let sheetDescription_5: String = "mode, it can be installed indoors or outdoors to keep tabs on pollution levels in your home, office, backyard, or neighborhood 24/7."
    }
    
    struct OnboardingPrivacy {
        static let title: String = "Your privacy"
        static let description: String = "Have a look at how we store and protect Your data and accept our privacy policy and terms of service before continuing."
        static let continueButton: String = "Accept"
        static let sheetButton: String = "Learn More"
    }
    
    struct OnboardingPrivacySheet {
        static let title: String = "Our privacy policy"
        static let description: String = """
            HabitatMap protects the personal data of AirCasting mobile application users, and fulfills conditions deriving from the law, especially from the Regulation (EU) 2016/679 of the European Parliament and of the Council of 27 April 2016 on the protection of natural persons with regard to the processing of personal data and on the free movement of such data, and repealing Directive 95/46/EC (GDPR). HabitatMap protects the security of the data of AirCasting app users using appropriate technical, logistical, administrative, and physical protection measures. AirCasting ensures that its employees and contractors are given training in protection of personal data.
            
            This privacy policy sets out the rules for HabitatMap’s processing of your data, including personal data, in relation to your use of the AirCasting mobile application.
            """
    }

    struct EmptyOnboarding {
        static let title: String = "Ready to get started?"
        static let description: String = "Record a new session to monitor your health & environment."
        static let newSession: String = "Record new session"
    }
}
