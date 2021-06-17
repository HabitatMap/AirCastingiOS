//
//  BlueTextButtonStyle.swift
//  AirCasting
//
//  Created by Lunar on 15/03/2021.
//

import SwiftUI

struct BlueTextButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(.accentColor)
            .font(Font.moderate(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
    }
}
#if DEBUG
struct BlueTextButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button("BlueTextButtonStyle") {}
            .buttonStyle(BlueTextButtonStyle())
    }
}
#endif
