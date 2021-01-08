//
//  AirButtonStyle.swift
//  AirCasting
//
//  Created by Lunar on 08/01/2021.
//

import SwiftUI

struct AirButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 40)
            .background(Color.accentColor)
            .cornerRadius(5)
            .padding(-3)
            .shadow(color: Color(white: 150/255, opacity: 0.5), radius: 9, x: 0, y: 1)
    }
}

struct AirButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button("AitButtonStyle") {}
            .buttonStyle(AirButtonStyle())
    }
}
