// Created by Lunar on 28/06/2021.
//

import AirCastingStyling
import MessageUI
import SwiftUI


struct ShareSessionView<VM: ShareSessionViewModel>: View {
    @ObservedObject var viewModel: VM
    @Binding var showSharingModal: Bool
    
    // This email logic will be moved to view model in the next task
    @State var email: String = ""
    @State var isShowingMailView = false
    @State var showingAlert = false
    @State var mailSendingResult: Result<MFMailComposeResult, Error>? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                title
                description
            }
            chooseStream
            shareButton
            //            descriptionMail
            //            createTextfield(placeholder: "Email", binding: $email)
            //                .padding(.vertical)
            VStack(alignment: .leading, spacing: 5) {
                //                oKButton
                cancelButton
            }
        }
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
        .sheet(isPresented: $viewModel.showSheet, content: {
            ActivityViewController(itemsToShare: [viewModel.sharingLink as Any]) {activityType,completed,returnedItems,error in
                //Sometimes this doesn't work
                showSharingModal.toggle()
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
            viewModel.shareLinkButtonGotPressed()
        }.buttonStyle(BlueButtonStyle())
            .padding(.bottom)
    }
    
    private var descriptionMail: some View {
        Text(Strings.SessionShare.emailDescription)
            .font(Fonts.muliHeading5)
            .foregroundColor(.aircastingGray)
    }
    
    private var oKButton: some View {
        Button(Strings.SessionShare.shareFileButton) {
            if MFMailComposeViewController.canSendMail() {
                isShowingMailView.toggle()
            } else {
                showingAlert = !isShowingMailView
                Log.info("Not showing mail view (cannot send email from this device")
            }
        }.buttonStyle(BlueButtonStyle())
            .sheet(isPresented: $isShowingMailView) { MailView(isShowing: $isShowingMailView, result: $mailSendingResult) }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(Strings.SessionShare.alertTitle), message: Text(Strings.SessionShare.alertDescription), dismissButton: .default(Text(Strings.SessionShare.alertButton)))
            }
    }
    
    private var cancelButton: some View {
        Button(Strings.BackendSettings.Cancel) {
            showSharingModal.toggle()
        }.buttonStyle(BlueTextButtonStyle())
    }
}

#if DEBUG
struct ShareSessionView_Previews: PreviewProvider {
    static var previews: some View {
        ShareSessionView(viewModel: DummyShareSessionViewModel(),showSharingModal: .constant(true))
    }
}
#endif
