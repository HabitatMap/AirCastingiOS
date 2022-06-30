//
//  Textfield.swift
//  AirCasting
//
//  Created by Lunar on 23/02/2021.
//

import SwiftUI

func createTextfield(placeholder: String, binding: Binding<String>, shouldWarnUser: Bool = false) -> some View {
    TextField(placeholder,
              text: binding)
    .padding()
    .frame(height: 50)
    .overlay(
        RoundedRectangle(cornerRadius: 8)
            .stroke(shouldWarnUser ? .red : Color.aircastingGray.opacity(0.1), lineWidth: 1)
    )
    .background(RoundedRectangle(cornerRadius: 8).fill(Color.aircastingGray.opacity(0.05)))
}

func createSecuredTextfield(placeholder: String, binding: Binding<String>, shouldWarnUser: Bool = false) -> some View {
    SecureField(placeholder,
                text: binding)
    .padding()
    .frame(height: 50)
    .disableAutocorrection(true)
    .overlay(
        RoundedRectangle(cornerRadius: 8)
            .stroke(shouldWarnUser ? .red : Color.aircastingGray.opacity(0.1), lineWidth: 1)
    )
    .background(RoundedRectangle(cornerRadius: 8).fill(Color.aircastingGray.opacity(0.05)))
}
