// Created by Lunar on 28/06/2021.
//

import AirCastingStyling
import MessageUI
import SwiftUI


struct ShareView: View {
    @Binding var showModal: Bool
    @State var email: String = ""
    @State var itemsForSharing: [String] = ["www.google.com"]
    #warning("Implement working share sheet")
    //To be sure that share sheet is working for now we are using "www.google.com" and then we will place some data there when making a logic to this
    @State var showSheet = false
    @State var isShowingMailView = false
    @State var showingAlert = false
    @State var mailSendingResult: Result<MFMailComposeResult, Error>? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                title
                description
            }
            checkBox
            shareButton
            descriptionMail
            createTextfield(placeholder: "Email", binding: $email)
                .padding(.vertical)
            VStack(alignment: .leading, spacing: 5) {
                oKButton
                cancelButton
            }
        }.sheet(isPresented: $showSheet, content: {
            ActivityViewController(itemsToShare: itemsForSharing)
        }).padding()
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
    #warning("This checkbox should be taken from the current streams available.")
    // It will be implemented on another branch and should be taken and implemented then here as well
    private var checkBox: some View {
        HStack {
            CheckBox(isSelected: true)
            Text(Strings.SessionShare.checkboxDescription)
        }.padding(.bottom)
    }
    
    private var shareButton: some View {
        Button(Strings.SessionShare.shareLinkButton) {
            showSheet.toggle()
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
            showModal.toggle()
        }.buttonStyle(BlueTextButtonStyle())
    }
}
