//
//  APIErorrHandling.swift
//  AirCasting
//
//  Created by Lunar on 19/03/2021.
//

import Foundation
import SwiftUI

enum AuthErrors: Error {
    //sign up
    case passwordTooShort
    case incorrectEmail
    case emptyTextfield
}

extension AuthErrors: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .passwordTooShort:
            return NSLocalizedString("Password is too short (minimum is 8 characters)", comment: "")
        case .incorrectEmail:
            return NSLocalizedString("The email address is incorrect.", comment: "")
        case .emptyTextfield:
            return NSLocalizedString("This field cannot be left blank.", comment: "")
            
        }
    }
}

func checkIfBlank(text: String) -> Bool {
    text.isEmpty ? true : false
}
func checkIsPasswordValid(password: String) -> Bool {
    password.count < 8 ? false : true
}
func checkIsEmailValid(email: String) -> Bool {
    email.contains("@") && email.contains(".") && email.count > 5
}
func errorMessage(text: String) -> some View {
    Text(text)
        .font(Font.moderate(size: 10))
        .foregroundColor(.aircastingRed)
}

func displayErrorAlert(error: NSError, errorTitle: String) -> Alert {
    if error.localizedDescription == "The data couldn’t be read because it is missing." {
            return Alert(title: Text("\(errorTitle)"),
                         message: Text("The profile name or password is incorrect. Please, try again. "),
                         dismissButton: .default(Text("Ok")))

    } else if error.localizedDescription == "A data connection is not currently allowed." {
        return Alert(title: Text("No Internet Connection"),
                     message: Text("Please, make sure your device is connected to the internet."),
                     dismissButton: .default(Text("Ok")))
    } else {
        return Alert(title: Text("Sign in error"),
                     message: Text(error.localizedDescription),
                     dismissButton: .default(Text("Ok")))
    }
}

