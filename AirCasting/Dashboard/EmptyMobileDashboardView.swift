//
//  EmptyDashboard.swift
//  AirCasting
//
//  Created by Lunar on 01/02/2021.
//

import AirCastingStyling
import SwiftUI
import Resolver

struct EmptyMobileDashboardViewMobile: View {
    @InjectedObject private var defaultSessionSynchronizerViewModel: SessionSynchronizationViewModel
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
                            .padding(.top)
                    }
                    Spacer()
                    emptyMobileDashboardText
                    EmptyDashboardButtonView(isFixed: false)
                    Spacer()
                }
                airBeamDescription
                    .padding([.horizontal, .bottom])
            }
        }
    }
}

private extension EmptyMobileDashboardViewMobile {
    
    private var emptyMobileDashboardText: some View {
        VStack(spacing: 14) {
            Text(Strings.EmptyDashboardMobile.title)
                .font(Fonts.boldTitle4)
                .foregroundColor(Color.darkBlue)
                .minimumScaleFactor(0.1)
            
            Text(Strings.EmptyDashboardMobile.description)
                .font(Fonts.muliHeading2)
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
                .fill(Color.aliceBlue)
                .cornerRadius(5)
                .shadow(color: Color.shadow, radius: 7, x: 0, y: 1)
            HStack {
                Image("handairBeam")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                VStack(alignment: .leading) {
                    Text(Strings.EmptyDashboardMobile.airBeamDescriptionText)
                        .font(Fonts.semiboldHeading1)
                        .foregroundColor(.aircastingGray)
                        .lineSpacing(15)
                    Text(Strings.EmptyDashboardMobile.airBeamDescriptionDescription)
                        .font(Fonts.muliHeading3)
                        .foregroundColor(.aircastingGray)
                }
            }
        }
        .frame(minWidth: 250, idealWidth: .infinity, maxWidth: .infinity, minHeight: 110, idealHeight: 110, maxHeight: 110, alignment: .center)
        .padding(.bottom)
    }
}
