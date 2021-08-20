//
//  File.swift
//  
//
//  Created by Lunar on 19/07/2021.
//

import SwiftUI

public struct UnFollowButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(.accentColor)
            .frame(width: 82, height: 23, alignment: .center)
            .background(Color.white)
            .font(.muli(size: 13, weight: .semibold))
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(Color.accentColor, lineWidth: 1))
    }
}
