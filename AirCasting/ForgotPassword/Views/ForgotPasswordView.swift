// Created by Lunar on 15/07/2021.
//

import AirCastingStyling
import Foundation
import SwiftUI

struct ForgotPasswordView<VM: ForgotPasswordViewModel>: View {
    @ObservedObject private var viewModel: VM
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    
    init(viewModel: VM) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            title
            createTextfield(placeholder: viewModel.emailInputTitle, binding: $email)
            VStack(alignment: .leading) {
                sendButton
                cancelButton
            }
        }.onChange(of: email, perform: { self.viewModel.emailChanged(to: $0) })
            .padding()
    }
    
    private var title: some View {
        Text(viewModel.title)
            .font(Fonts.boldTitle1)
            .foregroundColor(.accentColor)
    }
    
    var sendButton: some View {
        Button(viewModel.actionTitle) {
            viewModel.sendNewPassword()
        }.alert(isPresented: Binding<Bool>(
            get: { self.viewModel.alert != nil },
            set: { _ in self.viewModel.alert = nil }
        )) {
            Alert(
                title: Text(viewModel.alert?.title ?? ""),
                message: Text(viewModel.alert?.message ?? ""),
                dismissButton: Alert.Button.default(Text(viewModel.alert?.actionTitle ?? ""), action: {
                    presentationMode.wrappedValue.dismiss()
                })
            )
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    var cancelButton: some View {
        Button(viewModel.cancelTitle) {
            presentationMode.wrappedValue.dismiss()
        }.buttonStyle(BlueTextButtonStyle())
    }
}
