//
//  File.swift
//  
//
//  Created by Lunar on 17/06/2021.
//

import SwiftUI

public struct BlueButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .cornerRadius(5)
            .padding(-3)
            .shadow(color: Color.shadow, radius: 9, x: 0, y: 1)
    }
}
