//
//  WhiteButtonStyle.swift
//  
//
//  Created by lunar  on 08/06/2022.
//

import SwiftUI

public struct WhiteButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(.accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.accentColor, lineWidth: 1))
            .padding(-3)            
    }
}
