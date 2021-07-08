// Created by Lunar on 28/06/2021.
//

import AirCastingStyling
import MessageUI
import SwiftUI

struct ShareViewModal: View {
    @Binding var showModal: Bool
    @State var email: String = ""
    @State var items: [Any]
    @State var sheet = false
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
        }.sheet(isPresented: $sheet, content: {
            ActivityViewController(itemsToShare: ["www.google.com"])
        })
            .padding()
    }
    
    private var title: some View {
        Text(Strings.sessionShare.title)
            .font(Font.moderate(size: 32, weight: .bold))
            .foregroundColor(.accentColor)
            .bold()
    }
    
    private var description: some View {
        Text(Strings.sessionShare.description)
            .font(Font.muli(size: 16))
            .foregroundColor(.aircastingGray)
    }
    
    private var checkBox: some View {
        HStack {
            CheckBox(isSelected: true)
            Text("dB")
        }.padding(.bottom)
    }
    
    private var shareButton: some View {
        Button("Share link") {
            sheet.toggle()
        }.buttonStyle(BlueButtonStyle())
            .padding(.bottom)
    }
    
    private var descriptionMail: some View {
        Text(Strings.sessionShare.emailDescription)
            .font(Font.muli(size: 12))
            .foregroundColor(.aircastingGray)
    }
    
    private var oKButton: some View {
        Button("Share file") {
            if MFMailComposeViewController.canSendMail() {
                isShowingMailView.toggle()
            } else {
                showingAlert = !isShowingMailView
                print("no email app")
            }
        }.buttonStyle(BlueButtonStyle())
            .sheet(isPresented: $isShowingMailView) { MailView(isShowing: $isShowingMailView, result: $mailSendingResult) }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("No Email app"), message: Text("Please, install Apple Email app"), dismissButton: .default(Text("Got it!")))
            }
    }
    
    private var cancelButton: some View {
        Button(Strings.BackendSettings.Cancel) {
            showModal.toggle()
        }.buttonStyle(BlueTextButtonStyle())
    }
}
