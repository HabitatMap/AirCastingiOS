//
//  CardShadow.swift
//  
//
//  Created by lunar  on 13/06/2022.
//

import SwiftUI

public struct CardShadow: ViewModifier {
    
    public func body(content: Content) -> some View {
        content
            .shadow(color: .sessionCardShadow, radius: 3, x: 1, y: 2)
            .shadow(color: .sessionCardShadow, radius: 3, x: -1, y: 2)
    }
}

public extension View {
    func cardShadow() -> some View {
        modifier(CardShadow())
    }
}
