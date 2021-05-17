//
//  EmptyDashboard.swift
//  AirCasting
//
//  Created by Lunar on 01/02/2021.
//

import SwiftUI

struct EmptyDashboardView: View {
    var body: some View {
        emptyState
    }
    
    private var emptyState: some View {
        VStack(spacing: 45) {
            Spacer()
            VStack(spacing: 14) {
                
                Text("Ready to get started?")
                    .font(Font.moderate(size: 24, weight: .bold))
                    .foregroundColor(Color.darkBlue)
                
                Text("Explore & follow existing AirCasting sessions or use your own device to record a new session and monitor your health & environment.")
                    .font(Font.muli(size: 16))
                    .foregroundColor(Color.aircastingGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(9.0)
                    .padding(.horizontal, 45)
            }
            VStack(spacing: 20) {
                Button(action: {}, label: {
                    Text("Record new session")
                        .bold()
                })
                .frame(maxWidth: 250)
                .buttonStyle(BlueButtonStyle())
                
                Button(action: {}, label: {
                    Text("Explore existing sessions")
                        .foregroundColor(.accentColor)
                })
            }
            Spacer()
        }
        .padding()
        .background(Color(red: 251/255, green: 253/255, blue: 255/255))
    }
}

#if DEBUG
struct EmptyDashboard_Previews: PreviewProvider {
    static var previews: some View {
        EmptyDashboardView()
    }
}
#endif
