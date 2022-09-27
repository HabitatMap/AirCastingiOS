// Created by Lunar on 28/06/2021.
//

import AirCastingStyling
import MessageUI
import SwiftUI

struct ShareSessionView<VM: ShareSessionViewModel>: View {
    @StateObject var viewModel: VM
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                VStack {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                        .padding(.bottom, 10)
                    Text(Strings.SessionShare.upToDateSessions)
                }
            } else {
                XMarkButton()
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        title
                        description
                    }
                    chooseStream
                    shareButton
                    descriptionMail
                    VStack(alignment: .leading, spacing: -5.0) {
                        createTextfield(placeholder: Strings.SessionShare.emailPlaceholder, binding: $viewModel.email)
                            .font(Fonts.moderateRegularHeading2)
                            .padding(.vertical)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                        if viewModel.showInvalidEmailError {
                            emailErrorLabel
                        }
                    }
                    .padding(.vertical)
                    VStack(alignment: .leading, spacing: 5) {
                        oKButton
                        cancelButton
                    }
                }
                .alert(item: $viewModel.alert, content: { $0.makeAlert() })
                .sheet(isPresented: $viewModel.showShareSheet, content: { viewModel.getSharePage() })
                .padding()
            }
        }
        .background(Color.aircastingBackground.ignoresSafeArea())
        .onAppear { viewModel.didAppear() }
    }
    
    private var title: some View {
        Text(Strings.SessionShare.title)
            .font(Fonts.muliHeavyTitle1)
            .foregroundColor(.darkBlue)
    }
    
    private var description: some View {
        Text(Strings.SessionShare.description)
            .font(Fonts.muliRegularHeading3)
            .foregroundColor(.aircastingGray)
    }
    
    private var chooseStream: some View {
        VStack(alignment: .leading) {
            ForEach(viewModel.streamOptions, id: \.id) { option in
                HStack {
                    CheckBox(isSelected: option.isSelected).onTapGesture {
                        viewModel.didSelect(option: option)
                    }
                    Text(option.title)
                        .font(Fonts.muliMediumHeading1)
                }
            }
        }.padding()
    }
    
    private var shareButton: some View {
        Button(Strings.SessionShare.shareLinkButton) {
            viewModel.shareLinkTapped()
        }
        .font(Fonts.muliBoldHeading1)
        .buttonStyle(BlueButtonStyle())
        .padding(.bottom)
    }
    
    private var descriptionMail: some View {
        Text(Strings.SessionShare.emailDescription)
            .font(Fonts.moderateRegularHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    private var emailErrorLabel: some View {
        Text(Strings.SessionShare.invalidEmailLabel)
            .font(Fonts.moderateRegularHeading5)
            .foregroundColor(.aircastingRed)
            .multilineTextAlignment(.leading)
    }
    
    private var oKButton: some View {
        Button(Strings.SessionShare.shareFileButton) {
            viewModel.shareEmailTapped()
        }
        .font(Fonts.muliBoldHeading1)
        .buttonStyle(BlueButtonStyle())
    }
    
    private var cancelButton: some View {
        Button(Strings.Commons.cancel) {
            viewModel.cancelTapped()
        }
        .font(Fonts.moderateRegularHeading2)
        .buttonStyle(BlueTextButtonStyle())
    }
}

#if DEBUG
struct ShareSessionView_Previews: PreviewProvider {
    static var previews: some View {
        ShareSessionView(viewModel: DummyShareSessionViewModel())
    }
}
#endif
