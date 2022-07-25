// Created by Lunar on 09/06/2021.
//

import SwiftUI
import AirCastingStyling
import Resolver

struct GetStarted: View {
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel
    
    var completion: () -> Void
    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                mainImage
                logoImage
            }
            descriptionText
            if featureFlagsViewModel.enabledFeatures.contains(.searchAndFollow) {
                continueToAirNearYouScreenButton
            } else {
                startButton
            }
            Spacer()
        }
    }
}

private extension GetStarted {
    var mainImage: some View {
        Image("Bitmap")
            .resizable()
            .edgesIgnoringSafeArea(.top)
    }
    
    var logoImage: some View {
        Image("AirCastingLogo")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 180)
            .padding()
    }
    
    var descriptionText: some View {
        Text(Strings.OnboardingGetStarted.description)
            .padding(.horizontal, 18)
            .font(Fonts.muliRegularHeading2)
            .lineSpacing(10.0)
            .foregroundColor(.aircastingGray)
    }
    
    var startButton: some View {
        NavigationLink(
            destination: AirBeamOnboarding(completion: completion),
            label: { getStarted }
        )
    }
    
    var getStarted: some View {
        Text(Strings.OnboardingGetStarted.getStarted)
            .font(Fonts.moderateBoldHeading1)
            .frame(maxWidth: .infinity)
            .navigationBarHidden(true)
            .buttonStyle(BlueTextButtonStyle())
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(lineWidth: 0.2)
                    .accentColor(Color.aircastingGray)
            )
            .padding()
            .padding(.bottom, 41)
    }
    
    var continueToAirNearYouScreenButton: some View {
        NavigationLink(
            destination: NearAirDescription(completion: completion),
            label: { getStarted }
        )
    }
}

#if DEBUG
struct GetStarted_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GetStarted(completion: {})
        }
    }
}
#endif
