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
        static let Ok: String = "Ok"
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
    
    enum ForgotPassword {
        static let title = "Forgot Password"
        static let description = "You will get en email with details after 'send new' button pressed"
        static let actionTitle = "Send new"
        static let emailInputTitle = "email or username"
        static let newPasswordSuccessMessage = "Email was sent. Please check your inbox for the details."
        static let newPasswordSuccessTitle = "Email was sent. Please check your inbox for the details."
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
}
