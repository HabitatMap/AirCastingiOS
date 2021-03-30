//
//  WhiteButtonStyle.swift
//  AirCasting
//
//  Created by Lunar on 14/02/2021.
//

import SwiftUI

struct WhiteSelectingButtonStyle: ButtonStyle {
    
    var isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .frame(maxWidth: .infinity, maxHeight: 80)
            .background(Color.white)
            .shadow( color: isSelected ? (Color.accentColor.opacity(0.5)) : (Color(white: 150/255, opacity: 0.2)),
                     radius: 9, x: 0, y: 1)
            .padding()
    }
}


struct WhiteButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button("click") {}
            .buttonStyle( WhiteSelectingButtonStyle(isSelected: false))
    }
}
