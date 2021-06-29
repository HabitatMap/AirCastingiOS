// Created by Lunar on 09/06/2021.
//

import SwiftUI
import AirCastingStyling

struct AirBeamOnboarding: View {
    var completion: () -> Void
    @State var showingHalfModal = false
    var body: some View {
        VStack(alignment: .leading) {
            progressBar
            mainImage
            titleText
            descriptionText
            continueButton
            buttonToShowScreen
        }
        .padding()
        .navigationBarHidden(true)
    }
    
    private struct ModalPopView: View {
        @Binding var showingHalfModal: Bool
        var body: some View {
            VStack(alignment: .leading) {
                sheetTitle
                    .padding()
                sheetDescription
                    .padding()
                Spacer()
            }
        }
        
        private var sheetTitle: some View {
            Text("How AirBeam works?")
                .font(Font.moderate(size: 28, weight: .bold))
                .foregroundColor(.aircastingMint)
        }
        
        private var sheetDescription: some View {
            VStack {
                Text("In")
                    + Text(" mobile ")
                    .foregroundColor(.aircastingMint)
                    .fontWeight(.bold)
                    + Text("mode, the AirBeam captures personal exposures.\n\n\nIn")
                    + Text(" fixed ")
                    .foregroundColor(.aircastingMint)
                    .fontWeight(.bold)
                    + Text("mode, it can be installed indoors or outdoors to keep tabs on pollution levels in your home, office, backyard, or neighborhood 24/7.")
            }
            .font(Font.muli(size: 16))
            .lineSpacing(10.0)
            .foregroundColor(.aircastingGray)
        }
    }
}

private extension AirBeamOnboarding {
    private var progressBar: some View {
        ProgressView(value: 0.325)
            .accentColor(.aircastingMint)
            .padding(.bottom, 20)
    }
    
    private var mainImage: some View {
        Image("AirBeamOnboard")
            .resizable()
            .scaledToFit()
            .padding()
    }
    
    private var titleText: some View {
        Text("Measure and map \nyour exposure \nto air pollution")
            .font(Font.moderate(size: 32, weight: .bold))
            .foregroundColor(.aircastingMint)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 20)
    }
    
    private var buttonToShowScreen: some View {
        Button(action: {
            showingHalfModal = true
        }, label: {
            Text("Learn More")
                .navigationBarTitle("")
                .navigationBarHidden(true)
                .font(Font.moderate(size: 16, weight: .semibold))
        })
        .buttonStyle(GreenTextButtonStyle())
        .sheet(isPresented: $showingHalfModal) { ModalPopView(showingHalfModal: self.$showingHalfModal) }
    }
    
    private var descriptionText: some View {
        Text("Connect AirBeam to measure air quality humidity, and temperature.")
            .font(Font.muli(size: 16))
            .foregroundColor(.aircastingGray)
            .lineSpacing(10.0)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 20)
    }
    
    private var continueButton: some View {
        NavigationLink(
            destination: PrivacyOnboarding(completion: completion),
            label: {
                Text("Continue")
                    .font(Font.moderate(size: 16, weight: .semibold))
            }
        )
        .buttonStyle(GreenButtonStyle())
    }
}

#if DEBUG
struct AirBeamOnboarding_Previews: PreviewProvider {
    static var previews: some View {
        AirBeamOnboarding(completion: {})
    }
}
#endif
