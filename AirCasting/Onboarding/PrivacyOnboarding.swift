// Created by Lunar on 09/06/2021.
//

import SwiftUI
import AirCastingStyling

struct PrivacyOnboarding: View {
    var completion: () -> Void
    @State var presentingModal = false
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            progressBar
            Spacer()
            titleText
            descriptionText
            VStack(spacing: 5) {
                continueButton
                learnMoreButton
            }
        }
        .padding()
        .navigationBarHidden(true)
    }
    
    struct ModalView: View {
        @Binding var presentedAsModal: Bool
        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    Spacer()
                    Button(action: { presentedAsModal = false }) {
                        HStack {
                            Image(systemName: "xmark")
                        }
                        .padding()
                    }
                }
                sheetTitle
                sheetDescription
                Spacer()
            }
        }

        private var sheetTitle: some View {
            Text("Our privacy policy")
                .font(Font.moderate(size: 28, weight: .bold))
                .foregroundColor(.accentColor)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
        }
        
        private var sheetDescription: some View {
            Text("""
            HabitatMap is an environmental technology non-profit building open-source, free, and low-cost environmental monitoring and data visualization solutions, like the AirBeam and the AirCasting platform. Our tools empower organizations and citizen scientists to measure pollution and advocate for equitable solutions to environmental health issues. We focus on low-income communities and communities of color living with disproportionate environmental burdens.
            
            HabitatMap will never collect any personally identifiable information about you through the AirCasting app or website unless you have provided it to us voluntarily, nor will we use any information gleaned from your Android device to market to you or pass your information to any third party. Both the AirCasting Android app and the AirCasting and HabitatMap websites are compliant with the EU General Data Protection Regulation.
            """)
                .font(Font.muli(size: 14))
                .lineSpacing(10.0)
                .padding()
                .foregroundColor(.aircastingGray)
                .multilineTextAlignment(.leading)
        }
    }
}

private extension PrivacyOnboarding {
    private var progressBar: some View {
        ProgressView(value: 0.525)
            .accentColor(.accentColor)
    }
    
    private var titleText: some View {
        Text("Your privacy")
            .font(Font.moderate(size: 32, weight: .bold))
            .foregroundColor(.accentColor)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 20)
    }
    
    private var descriptionText: some View {
        Text("Have a look at how we store and protect Your data and accept our privacy policy and terms of service before continuing.")
            .font(Font.muli(size: 16))
            .foregroundColor(.aircastingGray)
            .lineSpacing(10.0)
            .multilineTextAlignment(.leading)
    }
    
    private var continueButton: some View {
        Button(action: {
            completion()
        }, label: {
            Text("Accept")
                .font(Font.moderate(size: 16, weight: .semibold))
        })
            .buttonStyle(BlueButtonStyle())
            .padding(.top, 20)
    }
    
    private var learnMoreButton: some View {
        Button(action: {
            presentingModal = true
        }, label: {
            Text("Learn More")
        })
            .buttonStyle(BlueTextButtonStyle())
            .sheet(isPresented: $presentingModal) { ModalView(presentedAsModal: self.$presentingModal) }
    }
}

#if DEBUG
struct PrivacyOnboarding_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyOnboarding(completion: {})
    }
}
#endif
