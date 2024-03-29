// Created by Lunar on 25/08/2021.
//

import SwiftUI
import AirCastingStyling

struct EmptyDashboardButtonView: View {
    @EnvironmentObject private var tabSelection: TabBarSelector
    @EnvironmentObject private var emptyDashboardButtonTapped: EmptyDashboardButtonTapped
    @EnvironmentObject private var exploreSessionsButton: ExploreSessionsButton
    var isFixed: Bool
    
    var body: some View {
        Button(action: {
            emptyDashboardButtonTapped.mobileWasTapped = !isFixed
            exploreSessionsButton.exploreSessionsButtonTapped = false
            tabSelection.updateSelection(to: .createSession)
        }, label: {
            if isFixed {
                Text(Strings.EmptyDashboardMobile.buttonFixed)
                    .bold()
            } else {
                Text(Strings.EmptyDashboardMobile.buttonMobile)
                    .bold()
            }
        })
        .font(Fonts.muliBoldHeading1)
        .frame(maxWidth: 250)
        .buttonStyle(BlueButtonStyle())
    }
}
