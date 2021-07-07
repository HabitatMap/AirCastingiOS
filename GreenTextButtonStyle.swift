//
//  File.swift
//
// Created by Lunar on 09/06/2021.
//
import SwiftUI

struct GreenTextButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(.aircastingMint)
            .font(Font.moderate(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .cornerRadius(5)
            .padding(.vertical, 12)
    }
}
#if DEBUG
struct GreenTextButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button("BlueTextButtonStyle") {}
            .buttonStyle(GreenTextButtonStyle())
    }
}
#endif
