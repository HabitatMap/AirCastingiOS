// Created by Lunar on 09/06/2021.
//

import SwiftUI
import AirCastingStyling

struct GetStarted: View {
    var completion: () -> Void
    var body: some View {
        NavigationView {
            VStack {
                mainImage
                Spacer()
                logoImage
                descriptionText
                startButton
                Spacer()
            }
        }
    }
}

private extension GetStarted {
    var mainImage: some View {
        Image("Bitmap")
            .resizable()
            .edgesIgnoringSafeArea(.top)
            .scaledToFill()
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
            .font(Fonts.GetStarted.description)
            .lineSpacing(10.0)
            .foregroundColor(.aircastingGray)
            .multilineTextAlignment(.center)
    }
    
    var startButton: some View {
        NavigationLink(
            destination: AirBeamOnboarding(completion: completion),
            label: {
                Text(Strings.OnboardingGetStarted.getStarted)
                    .frame(maxWidth:.infinity)
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
            }
        ).buttonStyle(BlueTextButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 5)
                .stroke(lineWidth: 0.1)
                .accentColor(Color.aircastingGray)
        )
        .padding()
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
