//
//  Textfield.swift
//  AirCasting
//
//  Created by Lunar on 23/02/2021.
//

import SwiftUI

func createTextfield(placeholder: String, binding: Binding<String>, isInputValid: Bool = false) -> some View {
    TextField(placeholder,
              text: binding)
    .padding()
    .frame(height: 50)
    .overlay(
        RoundedRectangle(cornerRadius: 8)
            .stroke(isInputValid ? .red : Color.textFieldBorderColor, lineWidth: 1)
    )
    .background(RoundedRectangle(cornerRadius: 8).fill(Color.textFieldBackgroundColor))
}

func createSecuredTextfield(placeholder: String, binding: Binding<String>, isInputValid: Bool = false) -> some View {
    SecureField(placeholder,
                text: binding)
    .padding()
    .frame(height: 50)
    .disableAutocorrection(true)
    .overlay(
        RoundedRectangle(cornerRadius: 8)
            .stroke(isInputValid ? .red : Color.textFieldBorderColor, lineWidth: 1)
    )
    .background(RoundedRectangle(cornerRadius: 8).fill(Color.textFieldBackgroundColor))
}
