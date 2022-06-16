//
//  File.swift
//  
//
//  Created by Lunar on 17/06/2021.
//

import SwiftUI

public struct GrayButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(.accentColor)
            .frame(height: 29)
            .padding(.horizontal, 13)
            .background(Color.buttonGray)
            .cornerRadius(50)
    }
}

