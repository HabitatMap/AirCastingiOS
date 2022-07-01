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
                ScrollView {
                    sheetDescription
                }
                Spacer()
            }
        }
        
        private var sheetTitle: some View {
            Text(Strings.OnboardingPrivacySheet.title)
                .font(Fonts.moderateBoldTitle2)
                .foregroundColor(.accentColor)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
        }
        
        private var sheetDescription: some View {
            Text(Strings.OnboardingPrivacySheet.description)
                .font(Fonts.muliRegularHeading4)
                .lineSpacing(10.0)
                .padding()
                .foregroundColor(.aircastingGray)
                .multilineTextAlignment(.leading)
        }
    }
}

private extension PrivacyOnboarding {
    private var progressBar: some View {
        ProgressView(value: 0.6)
            .accentColor(.accentColor)
    }
    
    private var titleText: some View {
        Text(Strings.OnboardingPrivacy.title)
            .font(Fonts.moderateBoldTitle1)
            .foregroundColor(.accentColor)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 20)
    }
    
    private var descriptionText: some View {
        Text(Strings.OnboardingPrivacy.description)
            .font(Fonts.muliRegularHeading3)
            .foregroundColor(.aircastingGray)
            .lineSpacing(10.0)
            .multilineTextAlignment(.leading)
    }
    
    private var continueButton: some View {
        Button(action: {
            completion()
        }, label: {
            Text(Strings.OnboardingPrivacy.continueButton)
                .font(Fonts.muliBoldHeading1)
        })
        .buttonStyle(BlueButtonStyle())
        .padding(.top, 20)
    }
    
    private var learnMoreButton: some View {
        Button(action: {
            presentingModal = true
        }, label: {
            Text(Strings.OnboardingPrivacy.sheetButton)
                .font(Fonts.moderateBoldHeading1)
        })
        .buttonStyle(BlueTextButtonStyle())
        .sheet(isPresented: $presentingModal) {
            WebView(url: Constants.PrivacyPolicy.url)
        }
    }
}

#if DEBUG
struct PrivacyOnboarding_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyOnboarding(completion: {})
    }
}
#endif
