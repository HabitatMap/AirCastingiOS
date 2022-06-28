//
//  File.swift
//  
//
//  Created by Lunar on 19/07/2021.
//

import SwiftUI

public struct FollowButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(.white)
            .frame(width: 82, height: 29, alignment: .center)
            .background(Color.accentColor)
            .font(.muli(size: 13, weight: .semibold))
            .cornerRadius(14)
    }
}
