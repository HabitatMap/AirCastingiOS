//
//  EmptyDashboard.swift
//  AirCasting
//
//  Created by Lunar on 01/02/2021.
//

import AirCastingStyling
import SwiftUI

struct EmptyDashboardView: View {
    @EnvironmentObject private var tabSelection: TabBarSelection
    @EnvironmentObject var selectedSection: SelectSection
    @EnvironmentObject var sessionSynchronizationController: SessionSynchronizationController
    var body: some View {
        emptyState
    }
    var shouldSessionFetch: Bool {
        (selectedSection.selectedSection == .mobileDormant || selectedSection.selectedSection == .fixed) && sessionSynchronizationController.syncInProgress
    }

    private var emptyState: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("dashboard-background-thing")
            
            VStack(spacing: 45) {
                VStack {
                    if shouldSessionFetch {
                        ProgressView(Strings.EmptyOnboarding.fetchingText)
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    Spacer()
                    VStack(spacing: 14) {
                        Text(Strings.EmptyOnboarding.title)
                            .multilineTextAlignment(.center)
                            .font(Font.moderate(size: 24, weight: .bold))
                            .foregroundColor(Color.darkBlue)
                            .minimumScaleFactor(0.1)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(Strings.EmptyOnboarding.description)
                            .font(Font.muli(size: 16))
                            .foregroundColor(Color.aircastingGray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(9.0)
                            .padding(.horizontal, 45)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 30)
                    
                    Button(action: {
                        tabSelection.selection = .createSession
                    }, label: {
                        Text(Strings.EmptyOnboarding.newSession)
                            .bold()
                    })
                    .frame(maxWidth: 250)
                    .buttonStyle(BlueButtonStyle())
                    Spacer()
                }
                airBeamDescription
                    .frame(minWidth: 250, idealWidth: .infinity, maxWidth: .infinity, minHeight: 110, idealHeight: 110, maxHeight: 110, alignment: .center)
                    .padding(.bottom)
            }
        }
        .padding()
        .background(Color(red: 251/255, green: 253/255, blue: 255/255))
    }
}
private extension EmptyDashboardView {
    private var airBeamDescription: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 251/255, green: 253/255, blue: 255/255))
                .cornerRadius(5)
                .shadow(color: Color(white: 150/255, opacity: 0.5), radius: 7, x: 0, y: 1)
            HStack {
                Image("handairBeam")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                VStack(alignment: .leading) {
                    Text(Strings.EmptyOnboarding.airBeamDescriptionText)
                        .font(Font.muli(size: 16, weight: .semibold))
                        .foregroundColor(.aircastingGray)
                        .lineSpacing(15)
                    Text(Strings.EmptyOnboarding.airBeamDescriptionDescription)
                        .font(Font.muli(size: 14))
                        .foregroundColor(.aircastingGray)
                }
            }
        }
    }
}

#if DEBUG
struct EmptyDashboard_Previews: PreviewProvider {
    static var previews: some View {
        EmptyDashboardView()
    }
}
#endif
