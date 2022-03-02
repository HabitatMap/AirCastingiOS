// Created by Lunar on 23/08/2021.
//
import AirCastingStyling
import SwiftUI
import Resolver

struct EmptyFixedDashboardView: View {
    @StateObject private var defaultSessionSynchronizerViewModel = SessionSynchronizationViewModel()
    @EnvironmentObject var selectedSection: SelectSection
    @EnvironmentObject private var tabSelection: TabBarSelection
    @EnvironmentObject private var exploreSessionsButton: ExploreSessionsButton
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel
    
    var shouldSessionFetch: Bool {
        (selectedSection.selectedSection == .mobileDormant || selectedSection.selectedSection == .fixed) && defaultSessionSynchronizerViewModel.syncInProgress
    }
    
    var body: some View {
        emptyState
    }

    private var emptyState: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("dashboard-background-thing")
            
            VStack() {
                if shouldSessionFetch {
                    ProgressView(Strings.EmptyDashboardFixed.fetchingText)
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.top)
                }
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
            tabSelection.selection = .createSession
        }, label: {
            Text(Strings.EmptyDashboardFixed.exploreSessionsButton)
                .bold()
        })
    }
    
    private var emptyFixedDashboardText: some View {
        VStack(spacing: 14) {
            Text(Strings.EmptyDashboardFixed.title)
                .font(Fonts.boldTitle4)
                .foregroundColor(Color.darkBlue)
                .minimumScaleFactor(0.1)
            
            Text(Strings.EmptyDashboardFixed.description)
                .font(Fonts.muliHeading2)
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
