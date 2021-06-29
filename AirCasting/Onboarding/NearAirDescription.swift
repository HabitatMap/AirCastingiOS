// Created by Lunar on 09/06/2021.
//

import SwiftUI

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
        ProgressView(value: 0.125)
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
        Text("How’s the air \nnear you?")
            .font(Font.moderate(size: 32, weight: .bold))
            .foregroundColor(.accentColor)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 30)
    }
    
    private var descriptionText: some View {
        Text("Find and follow a fixed air quality monitor near you and know how clean or polluted your air is right now.")
            .font(Font.muli(size: 16))
            .foregroundColor(.aircastingGray)
            .multilineTextAlignment(.leading)
            .lineSpacing(10.0)
            .padding(.bottom, 20)
    }
    
    private var continueButton: some View {
        NavigationLink(
            destination: AirBeamOnboarding(completion: completion),
            label: {
                Text("Continue")
                    .font(Font.moderate(size: 16, weight: .semibold))
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
