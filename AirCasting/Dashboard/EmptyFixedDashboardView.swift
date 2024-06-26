// Created by Lunar on 23/08/2021.
//
import AirCastingStyling
import SwiftUI
import Resolver

struct EmptyFixedDashboardView: View {
    @EnvironmentObject private var tabSelection: TabBarSelector
    @EnvironmentObject private var exploreSessionsButton: ExploreSessionsButton
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel
    
    var body: some View {
        emptyState
    }

    private var emptyState: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("dashboard-background-thing")
            
            VStack() {
                Spacer()
                VStack(spacing: 20) {
                    emptyFixedDashboardText
                    EmptyDashboardButtonView(isFixed: true)
                    if featureFlagsViewModel.enabledFeatures.contains(.searchAndFollow) {
                        exploreExistingSessionsButton
                    }
                }
                // Additional padding to put the text at similar height
                // as in mobile empty dashboard
                .padding(.bottom, 100)
                Spacer()
            }.frame(maxWidth: .infinity)
        }
    }
}

private extension EmptyFixedDashboardView {
    private var exploreExistingSessionsButton: some View {
        Button(action: {
            exploreSessionsButton.exploreSessionsButtonTapped = true
            tabSelection.update(to: .createSession)
        }, label: {
            Text(Strings.EmptyDashboardFixed.exploreSessionsButton)
                .font(Fonts.moderateBoldHeading1)
        })
    }
    
    private var emptyFixedDashboardText: some View {
        VStack(spacing: 14) {
            Text(Strings.EmptyDashboardFixed.title)
                .font(Fonts.moderateBoldTitle4)
                .foregroundColor(Color.darkBlue)
                .minimumScaleFactor(0.1)
            
            Text(featureFlagsViewModel.enabledFeatures.contains(.searchAndFollow) ? Strings.EmptyDashboardFixed.exploreSessionsDescription : Strings.EmptyDashboardFixed.description)
                .font(Fonts.muliRegularHeading3)
                .foregroundColor(Color.aircastingGray)
                .lineSpacing(9.0)
                .padding(.horizontal, 35)
        }
        .padding(.bottom, 30)
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
    }
}

struct EmptyDashboardViewFixed_Previews: PreviewProvider {
    static var previews: some View {
        EmptyFixedDashboardView()
    }
}
