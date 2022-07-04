// Created by Lunar on 09/06/2021.
//

import SwiftUI
import AirCastingStyling

struct AirBeamOnboarding: View {
    var completion: () -> Void
    @State var sheetIsPresented = false
    
    var body: some View {
        VStack(alignment: .leading) {
            progressBar
            mainImage
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
            titleText
            descriptionText
            continueButton
            buttonToShowScreen
        }
        .padding()
        .navigationBarHidden(true)
    }
//    
    private struct ModalPopView: View {
        @Binding var sheetIsPresented: Bool
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Button(action: {
                        sheetIsPresented = false
                    }, label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.aircastingDarkGray)
                            .imageScale(.large)
                    })
                    .padding()
                }

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
            StringCustomizer.customizeString(Strings.OnboardingAirBeamSheet.sheetDescription_1,
                                             using: [Strings.OnboardingAirBeamSheet.fixed,
                                                     Strings.OnboardingAirBeamSheet.mobile],
                                             color: .aircastingMint,
                                             standardFont: Fonts.muliHeading2)
                .lineSpacing(10.0)
                .multilineTextAlignment(.leading)
        }
    }
}

private extension AirBeamOnboarding {
    private var progressBar: some View {
        ProgressView(value: 0.4)
            .accentColor(.aircastingMint)
            .padding(.bottom, 30)
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
            sheetIsPresented = true
        }, label: {
            Text(Strings.OnboardingAirBeam.sheetButton)
                .navigationBarTitle("")
                .navigationBarHidden(true)
                .font(Fonts.semiboldHeading1)
        })
        .buttonStyle(GreenTextButtonStyle())
        .sheet(isPresented: $sheetIsPresented) { ModalPopView(sheetIsPresented: self.$sheetIsPresented) }
    }
    
    private var descriptionText: some View {
        Text(Strings.OnboardingAirBeam.description)
            .font(Fonts.muliHeading2)
            .foregroundColor(.aircastingGray)
            .lineSpacing(10.0)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 30)
    }
    
    private var continueButton: some View {
        NavigationLink(
            destination: PrivacyOnboarding(completion: completion),
            label: {
                Text(Strings.Commons.continue)
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
