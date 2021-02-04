//
//  AirButtonStyle.swift
//  AirCasting
//
//  Created by Lunar on 08/01/2021.
//

import SwiftUI

struct BlueButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .cornerRadius(5)
            .padding(-3)
            .shadow(color: Color(white: 150/255, opacity: 0.5), radius: 9, x: 0, y: 1)
    }
}

struct AirButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button("AitButtonStyle") {}
            .buttonStyle(BlueButtonStyle())
    }
}
