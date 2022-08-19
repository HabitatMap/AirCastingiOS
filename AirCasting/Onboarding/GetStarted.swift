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
            Spacer()
            logoImage
            descriptionText
            if featureFlagsViewModel.enabledFeatures.contains(.searchAndFollow) {
                continueToAirNearYouScreenButton
            } else {
                startButton
            }
        }
        .background(
            ZStack {
                Color.aircastingBackground.ignoresSafeArea()
                VStack {
                    mainImage
                    Spacer()
                }
                .edgesIgnoringSafeArea(.top)
            }
        )
    }
}

private extension GetStarted {
    var mainImage: some View {
        GeometryReader { geo in
            if UIDevice.current.userInterfaceIdiom != .pad {
                Image("Bitmap")
                    .resizable()
                    .scaledToFit()
            } else {
                Image("Bitmap")
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: geo.size.height * 0.7)
            }
        }
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
            label: {
                Text(Strings.OnboardingGetStarted.getStarted)
                    .font(Fonts.muliBoldHeading1)
            }
        )
        .buttonStyle(BlueButtonStyle())
        .padding()
        .padding(.bottom, 42)
    }
    
    var continueToAirNearYouScreenButton: some View {
        NavigationLink(
            destination: NearAirDescription(completion: completion),
            label: {
                Text(Strings.OnboardingGetStarted.getStarted)
                    .font(Fonts.muliBoldHeading1)
            }
        )
        .buttonStyle(BlueButtonStyle())
        .padding()
        .padding(.bottom, 42)
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
