//
//  Textfield.swift
//  AirCasting
//
//  Created by Lunar on 23/02/2021.
//

import SwiftUI

func createTextfield(placeholder: String, binding: Binding<String> ) -> some View {
    TextField(placeholder,
              text: binding)
        .padding()
        .frame(height: 50)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.aircastingGray.opacity(0.1), lineWidth: 1)
        )
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.aircastingGray.opacity(0.05)))
}
