//
//  CheckBox.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import SwiftUI

struct CheckBox: View {
    var body: some View {
        checkbox
    }
    var isSelected: Bool
    
    var checkbox: some View {
        ZStack {
            Color.accentColor
                .frame(width: 20, height: 20)
                .clipShape(Circle())
            Color.white
                .frame(width: 16, height: 16)
                .clipShape(Circle())
            Color.accentColor
                .frame(width: 12, height: 12)
                .clipShape(Circle())
                .opacity(isSelected ? 1.0 : 0.0)
        }
    }
}

struct CheckBox_Previews: PreviewProvider {
    static var previews: some View {
        CheckBox(isSelected: false)
    }
}
