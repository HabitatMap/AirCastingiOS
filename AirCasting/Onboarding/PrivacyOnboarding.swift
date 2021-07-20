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
            HabitatMap protects the personal data of AirCasting mobile application users, and fulfills conditions deriving from the law, especially from the Regulation (EU) 2016/679 of the European Parliament and of the Council of 27 April 2016 on the protection of natural persons with regard to the processing of personal data and on the free movement of such data, and repealing Directive 95/46/EC (GDPR). HabitatMap protects the security of the data of AirCasting app users using appropriate technical, logistical, administrative, and physical protection measures. AirCasting ensures that its employees and contractors are given training in protection of personal data.
            
            This privacy policy sets out the rules for HabitatMap’s processing of your data, including personal data, in relation to your use of the AirCasting mobile application.
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
