//
//  File.swift
//  
//
//  Created by Lunar on 17/06/2021.
//

import SwiftUI

public struct BlueTextButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(.accentColor)
            .font(Font.moderate(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
    }
}
