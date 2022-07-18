//
//  File.swift
//  
//
//  Created by Lunar on 17/06/2021.
//

import SwiftUI

public struct WhiteSelectingButtonStyle: ButtonStyle {
    var isSelected: Bool
    
    public init(isSelected: Bool) {
        self.isSelected = isSelected
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .frame(maxWidth: .infinity, maxHeight: 80)
            .background(Color.aircastingWhite)
            .shadow( color: isSelected ? (Color.accentColor.opacity(0.5)) : (Color(white: 150/255, opacity: 0.2)),
                     radius: 9, x: 0, y: 1)
            .padding()
    }
}
