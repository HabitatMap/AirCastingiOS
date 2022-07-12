//
//  EditButton.swift
//  AirCasting
//
//  Created by Lunar on 19/01/2021.
//

import SwiftUI

struct EditButtonView: View {
    var body: some View {
        dots
    }
    
    var dot: some View {
        Color.aircastingGray
            .frame(width: 4, height: 4)
            .clipShape(Circle())
    }
    var dots: some View {
        HStack(spacing: 4) {
            dot
            dot
            dot
        }
    }
}

struct EditButton_Previews: PreviewProvider {
    static var previews: some View {
        EditButtonView()
    }
}
