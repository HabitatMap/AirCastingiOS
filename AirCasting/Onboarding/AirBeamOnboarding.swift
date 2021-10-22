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
            HStack() {
                Spacer()
                mainImage
                Spacer()
            }
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
                Spacer()
                sheetTitle
                    .padding()
                sheetDescription
                    .padding()
                Spacer()
            }
        }
        
        private var sheetTitle: some View {
            Text(Strings.OnboardingAirBeamSheet.sheetTitle)
                .font(Fonts.boldTitle2)
                .foregroundColor(.aircastingMint)
        }
        
        private var sheetDescription: some View {
            VStack {
                Text(Strings.OnboardingAirBeamSheet.sheetDescription_1)
                    + Text(Strings.OnboardingAirBeamSheet.sheetDescription_2)
                    .foregroundColor(.aircastingMint)
                    .fontWeight(.bold)
                    + Text(Strings.OnboardingAirBeamSheet.sheetDescription_3)
                    + Text(Strings.OnboardingAirBeamSheet.sheetDescription_4)
                    .foregroundColor(.aircastingMint)
                    .fontWeight(.bold)
                    + Text(Strings.OnboardingAirBeamSheet.sheetDescription_5)
            }
            .font(Fonts.muliHeading2)
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
        Text(Strings.OnboardingAirBeam.title)
            .font(Fonts.boldTitle1)
            .foregroundColor(.aircastingMint)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 20)
    }
    
    private var buttonToShowScreen: some View {
        Button(action: {
            showingHalfModal = true
        }, label: {
            Text(Strings.OnboardingAirBeam.sheetButton)
                .navigationBarTitle("")
                .navigationBarHidden(true)
                .font(Fonts.semiboldHeading1)
        })
        .buttonStyle(GreenTextButtonStyle())
        .sheet(isPresented: $showingHalfModal) { ModalPopView(showingHalfModal: self.$showingHalfModal) }
    }
    
    private var descriptionText: some View {
        Text(Strings.OnboardingAirBeam.description)
            .font(Fonts.muliHeading2)
            .foregroundColor(.aircastingGray)
            .lineSpacing(10.0)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 20)
    }
    
    private var continueButton: some View {
        NavigationLink(
            destination: PrivacyOnboarding(completion: completion),
            label: {
                Text(Strings.OnboardingAirBeam.continueButton)
                    .font(Fonts.semiboldHeading1)
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
