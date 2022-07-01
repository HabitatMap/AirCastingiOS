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
            return Strings.AuthErrors.passwordTooShort
        case .incorrectEmail:
            return Strings.AuthErrors.incorrectEmail
        case .emptyTextfield:
            return Strings.AuthErrors.emptyTextfield
            
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
        .font(Fonts.moderateRegularHeading6)
        .foregroundColor(.aircastingRed)
}
