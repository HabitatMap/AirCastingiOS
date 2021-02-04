//
//  ConnectingABView.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import SwiftUI

struct ConnectingABView: View {
    var body: some View {
        VStack(spacing: 50) {
            ProgressView(value: 0.5)
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
        }
        .padding()
    }
    
    var titleLabel: some View {
        Text("Connecting")
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    var messageLabel: some View {
        Text("This should take less than 10 seconds.")
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)

    }
}
struct ConnectingABView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectingABView()
    }
}
