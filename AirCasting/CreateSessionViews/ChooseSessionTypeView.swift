//
//  CreateSessionView.swift
//  AirCasting
//
//  Created by Lunar on 05/02/2021.
//

import SwiftUI
import CoreBluetooth

struct ChooseSessionTypeView: View {
    
    @State private var isInfoPresented: Bool = false
    @Environment(\.managedObjectContext) var context
    @StateObject var sessionContext = CreateSessionContext()
    @State private var isFixedNavigationLinkActive = false
    @State private var isMobileNavigationLinkActive = false
    
    var body: some View {
        VStack(spacing: 50) {
            VStack(alignment: .leading, spacing: 10) {
                titleLabel
                messageLabel
            }
            .background(Color.white)
            .padding(.horizontal)
            
            VStack {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        recordNewLabel
                        Spacer()
                        moreInfo
                    }
                    HStack(spacing: 60) {
                        fixedSessionButton
                        mobileSessionButton
                    }
                }
                Spacer()
            }
            .padding()
            .background(
                Color.aircastingBackground.opacity(0.25)
                    .ignoresSafeArea()
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .environmentObject(sessionContext)
    }
    var titleLabel: some View {
        Text("Let's begin")
            .font(Font.moderate(size: 32,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    var messageLabel: some View {
        Text("How would you like to add your session?")
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)
    }
    var recordNewLabel: some View {
        Text("Record a new session")
            .font(Font.muli(size: 14, weight: .bold))
            .foregroundColor(.aircastingDarkGray)
    }
    
    var moreInfo: some View {
        Button(action: {
            isInfoPresented = true
        }, label: {
            Text("more info")
                .font(Font.moderate(size: 14))
                .foregroundColor(.accentColor)
        })
        .sheet(isPresented: $isInfoPresented, content: {
            moreInfoText
        })
    }
    
    var fixedSessionButton: some View {
        Button(action: {
            createNewSession(isSessionFixed: true)
            isFixedNavigationLinkActive = true
        }) {
            fixedSessionLabel
        }
        .background(
            NavigationLink(destination: TurnOnBluetoothView(),
                           isActive: $isFixedNavigationLinkActive) {
                EmptyView()
            })
    }
    
    var mobileSessionButton: some View {
        Button(action: {
            createNewSession(isSessionFixed: false)
            isMobileNavigationLinkActive = true
        }) {
            fixedSessionLabel
        }
        .background(
            NavigationLink(destination: SelectDeviceView(),
                           isActive: $isMobileNavigationLinkActive) {
                EmptyView()
            })
    }
    
    var fixedSessionLabel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fixed session")
                .font(Font.muli(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            Text("for measuring in one place")
                .font(Font.muli(size: 14, weight: .regular))
                .foregroundColor(.aircastingGray)
        }
        .padding()
        .frame(maxWidth: 145, maxHeight: 145)
        .background(Color.white)
        .shadow(color: Color(white: 150/255, opacity: 0.5), radius: 9, x: 0, y: 1)
    }
    
    var mobileSessionLabel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mobile session")
                .font(Font.muli(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            Text("for moving around")
                .font(Font.muli(size: 14, weight: .regular))
                .foregroundColor(.aircastingGray)
        }
        .padding()
        .frame(maxWidth: 145, maxHeight: 145)
        .background(Color.white)
        .shadow(color: Color(white: 150/255, opacity: 0.5), radius: 9, x: 0, y: 1)
    }
    
    var moreInfoText: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Session types")
                .font(Font.moderate(size: 28, weight: .bold))
                .foregroundColor(.accentColor)
            Text("If you plan on moving around with the AirBeam3 while recording air quality measurement, configure the AirBeam to record a mobile session. When recording a mobile AirCasting session, measurements are created, timestamped, and geolocated once per second.")
            Text("If you plan to leave the AirBeam3 indoors or hang it outside then configure it to record a fixed session. When recording fixed AirCasting sessions, measurements are created and timestamped once per minute, and geocoordinates are fixed to a set location.")
        }
        .font(Font.muli(size: 16))
        .lineSpacing(12)
        .foregroundColor(.aircastingGray)
        .padding()
    }
    
    private func createNewSession(isSessionFixed: Bool) {
        sessionContext.sessionUUID = UUID().uuidString
        if isSessionFixed {
            sessionContext.sessionType = SessionType.FIXED
        } else {
            sessionContext.sessionType = SessionType.MOBILE
        }
    }
}

struct CreateSessionView_Previews: PreviewProvider {
    static var previews: some View {
        ChooseSessionTypeView()
    }
}
