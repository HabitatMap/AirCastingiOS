//
//  EmptyDashboard.swift
//  AirCasting
//
//  Created by Lunar on 01/02/2021.
//

import AirCastingStyling
import SwiftUI

struct EmptyMobileDashboardViewMobile: View {
    #warning("Please switch to protocol ASAP")
    @EnvironmentObject var defaultSessionSynchronizerViewModel: DefaultSessionSynchronizationViewModel
    @EnvironmentObject var selectedSection: SelectSection
    
    var shouldSessionFetch: Bool {
        (selectedSection.selectedSection == .mobileDormant || selectedSection.selectedSection == .fixed) && defaultSessionSynchronizerViewModel.syncInProgress
    }
    
    var body: some View {
        emptyState
    }

    private var emptyState: some View {
        ZStack(alignment: .bottomTrailing) {
            
            Image("dashboard-background-thing")
            
            VStack(spacing: 45) {
                VStack {
                    if shouldSessionFetch {
                        ProgressView(Strings.EmptyDashboardFixed.fetchingText)
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    Spacer()
                    emptyMobileDashboardText
                    EmptyDashboardButtonView(isFixed: false)
                    Spacer()
                }
                airBeamDescription
            }
        }
        .padding()
        .background(Color(red: 251/255, green: 253/255, blue: 255/255))
    }
}

private extension EmptyMobileDashboardViewMobile {
    
    private var emptyMobileDashboardText: some View {
        VStack(spacing: 14) {
            Text(Strings.EmptyDashboardMobile.title)
                .font(Font.moderate(size: 24, weight: .bold))
                .foregroundColor(Color.darkBlue)
                .minimumScaleFactor(0.1)
            
            Text(Strings.EmptyDashboardMobile.description)
                .font(Font.muli(size: 16))
                .foregroundColor(Color.aircastingGray)
                .lineSpacing(9.0)
                .padding(.horizontal, 35)
        }
        .padding(.bottom, 30)
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
    }
    
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
                    Text(Strings.EmptyDashboardMobile.airBeamDescriptionText)
                        .font(Font.muli(size: 16, weight: .semibold))
                        .foregroundColor(.aircastingGray)
                        .lineSpacing(15)
                    Text(Strings.EmptyDashboardMobile.airBeamDescriptionDescription)
                        .font(Font.muli(size: 14))
                        .foregroundColor(.aircastingGray)
                }
            }
        }
        .frame(minWidth: 250, idealWidth: .infinity, maxWidth: .infinity, minHeight: 110, idealHeight: 110, maxHeight: 110, alignment: .center)
        .padding(.bottom)
    }
}

#if DEBUG
struct EmptyDashboard_Previews: PreviewProvider {
    static var previews: some View {
        EmptyMobileDashboardViewMobile()
    }
}
#endif
