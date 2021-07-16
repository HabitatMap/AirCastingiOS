// Created by Lunar on 28/06/2021.
//

import AirCastingStyling
import SwiftUI

struct ShareViewModal: View {
    @Environment(\.presentationMode) var presentationMode
    @State var email: String = ""
    
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
        }
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
            presentationMode.wrappedValue.dismiss()
        }.buttonStyle(BlueButtonStyle())
        .padding(.bottom)
    }
    
    private var descriptionMail: some View {
        Text(Strings.sessionShare.emailDescription)
            .font(.subheadline)
            .foregroundColor(.aircastingGray)
    }
    
    private var oKButton: some View {
        Button("Share file") {
            presentationMode.wrappedValue.dismiss()
        }.buttonStyle(BlueButtonStyle())
    }
    
    private var cancelButton: some View {
        Button(Strings.BackendSettings.Cancel) {
            presentationMode.wrappedValue.dismiss()
        }.buttonStyle(BlueTextButtonStyle())
    }
}
