//
//  PowerABView.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import SwiftUI

struct PowerABView: View {
    @Binding var dashboardIsActive : Bool
    
    var body: some View {
        VStack(spacing: 45) {
            ProgressView(value: 0.25)
            Image("2-power")
            VStack(alignment: .leading, spacing: 13) {
                titleLabel
                messageLabel
            }
            continueButton
                .buttonStyle(BlueButtonStyle())
        }
        .padding()
        
    }
    
    var titleLabel: some View {
        Text("Power on your AirBeam")
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    var messageLabel: some View {
        Text("If using AirBeam 2, wait for the conncection indicator to change from red to green before continuing.")
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)

    }
    var continueButton: some View {
        NavigationLink(destination: SelectPeripheralView(dashboardIsActive: $dashboardIsActive)) {
            Text("Continue")
                .frame(maxWidth: .infinity)
        }
    }
}
//
//struct PowerABView_Previews: PreviewProvider {
//    static var previews: some View {
//        PowerABView()
//    }
//}
