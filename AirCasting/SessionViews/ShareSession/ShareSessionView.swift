// Created by Lunar on 28/06/2021.
//

import AirCastingStyling
import MessageUI
import SwiftUI


struct ShareSessionView<VM: ShareSessionViewModel>: View {
    @ObservedObject var viewModel: VM
    
    var body: some View {
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
        .sheet(isPresented: $viewModel.showShareSheet, content: {
            ActivityViewController(itemsToShare: [viewModel.sharingLink as Any]) { activityType, completed, returnedItems, error in
                viewModel.sharingFinished()
            }
        })
        .padding()
    }
    
    private var title: some View {
        Text(Strings.SessionShare.title)
            .font(Fonts.boldTitle1)
            .foregroundColor(.accentColor)
    }
    
    private var description: some View {
        Text(Strings.SessionShare.description)
            .font(Fonts.muliHeading2)
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
                }
            }
        }.padding()
    }
    
    private var shareButton: some View {
        Button(Strings.SessionShare.shareLinkButton) {
            viewModel.shareLinkTapped()
        }.buttonStyle(BlueButtonStyle())
            .padding(.bottom)
    }
    
    private var descriptionMail: some View {
        Text(Strings.SessionShare.emailDescription)
            .font(Fonts.muliHeading5)
            .foregroundColor(.aircastingGray)
    }
    
    private var emailErrorLabel: some View {
        Text(Strings.SessionShare.invalidEmailLabel)
            .font(Fonts.regularHeading5)
            .foregroundColor(.aircastingRed)
            .multilineTextAlignment(.leading)
    }
    
    private var oKButton: some View {
        Button(Strings.SessionShare.shareFileButton) {
            viewModel.shareEmailTapped()
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    private var cancelButton: some View {
        Button(Strings.Commons.cancel) {
            viewModel.cancelTapped()
        }.buttonStyle(BlueTextButtonStyle())
    }
}

#if DEBUG
struct ShareSessionView_Previews: PreviewProvider {
    static var previews: some View {
        ShareSessionView(viewModel: DummyShareSessionViewModel())
    }
}
#endif