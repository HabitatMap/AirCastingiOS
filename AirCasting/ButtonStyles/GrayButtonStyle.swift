//
//  GrayButtonStyle.swift
//  AirCasting
//
//  Created by Lunar on 12/01/2021.
//

import SwiftUI

struct GrayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(.accentColor)
            .padding(.vertical, 5)
            .padding(.horizontal, 13)
            .background(Color.buttonGray)
            .cornerRadius(50)
            .padding(-3)
    }
}

struct GrayButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button("click") {}
            .buttonStyle(GrayButtonStyle())
    }
}
