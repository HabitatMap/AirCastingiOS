//
//  File.swift
//
// Created by Lunar on 05/04/2021.
//
import SwiftUI

public struct MultiSelectButtonStyle: ButtonStyle {
    var isSelected: Bool
    
    public init(isSelected: Bool) {
        self.isSelected = isSelected
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding([.all], 8)
            .background(isSelected ? Color.accentColor : Color.buttonGray)
            .clipShape(Capsule())
            .padding(-3)
            .shadow(color: Color.shadow, radius: 9, x: 0, y: 1)

    }
}
