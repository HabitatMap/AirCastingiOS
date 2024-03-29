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
    var body: some View {
        emptyState
    }

    private var emptyState: some View {
        ZStack(alignment: .bottomTrailing) {
            
            Image("dashboard-background-thing")
            
            VStack(spacing: 45) {
                VStack {
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
            StringCustomizer.customizeString(Strings.EmptyDashboardMobile.title,
                                             using: [Strings.EmptyDashboardMobile.titleDivider],
                                             standardFontWeight: .bold,
                                             color: .darkBlue,
                                             standardColor: .darkBlue,
                                             font: Fonts.moderateBoldTitle4,
                                             standardFont: Fonts.moderateBoldTitle4,
                                             makeNewLineAfterCustomized: true)
                .minimumScaleFactor(0.1)
            Text(Strings.EmptyDashboardMobile.description)
                .font(Fonts.muliRegularHeading3)
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
                        .font(Fonts.moderateSemiboldHeading1)
                        .foregroundColor(.aircastingGray)
                        .lineSpacing(15)
                    Text(Strings.EmptyDashboardMobile.airBeamDescriptionDescription)
                        .font(Fonts.muliRegularHeading5)
                        .foregroundColor(.aircastingGray)
                }
            }
        }
        .frame(minWidth: 250, idealWidth: .infinity, maxWidth: .infinity, minHeight: 110, idealHeight: 110, maxHeight: 110, alignment: .center)
        .padding(.bottom)
    }
}
