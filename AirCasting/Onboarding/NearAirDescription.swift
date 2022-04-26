// Created by Lunar on 09/06/2021.
//

import SwiftUI
import AirCastingStyling

struct NearAirDescription: View {
    var completion: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            progressView
            mainImage
            VStack(alignment: .leading, spacing: 15) {
                titleText
                descriptionText
            }
            continueButton
        }
        .padding()
        .navigationBarHidden(true)
    }
}

private extension NearAirDescription {
    private var progressView: some View {
        ProgressView(value: 0.2)
            .accentColor(.accentColor)
            .padding(.bottom, 20)
    }
    
    private var mainImage: some View {
        Image("Air")
            .resizable()
            .scaledToFit()
            .padding()
    }
    
    private var titleText: some View {
        Text(Strings.OnboardingNearAir.title)
            .font(Fonts.boldTitle1)
            .foregroundColor(.accentColor)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 30)
            .scaledToFill()
    }
    
    private var descriptionText: some View {
        Text(Strings.OnboardingNearAir.description)
            .font(Fonts.muliHeading2)
            .foregroundColor(.aircastingGray)
            .multilineTextAlignment(.leading)
            .lineSpacing(10.0)
            .padding(.bottom, 20)
    }
    
    private var continueButton: some View {
        NavigationLink(
            destination: AirBeamOnboarding(completion: completion),
            label: {
                Text(Strings.Commons.continue)
                    .font(Fonts.semiboldHeading1)
            }
        )
        .buttonStyle(BlueButtonStyle())
        .padding(.bottom, 30)
    }
}

#if DEBUG
struct NearAirDescription_Previews: PreviewProvider {
    static var previews: some View {
        NearAirDescription(completion: {})
    }
}
#endif
