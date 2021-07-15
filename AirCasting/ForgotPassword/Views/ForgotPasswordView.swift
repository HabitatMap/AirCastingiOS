// Created by Lunar on 15/07/2021.
//

import Foundation
import SwiftUI
import AirCastingStyling

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
            description
            sendButton
        }.onChange(of: email, perform: { self.viewModel.emailChanged(to: $0) })
        .padding()
    }
    
    private var title: some View {
        Text(viewModel.title)
            .font(Font.moderate(size: 32, weight: .bold))
            .foregroundColor(.accentColor)
    }
    
    private var description: some View {
        Text(viewModel.description)
            .font(Font.muli(size: 16))
            .foregroundColor(.aircastingGray)
    }
    
    var sendButton: some View {
        Button(viewModel.actionTitle) {
            viewModel.sendNewPassword()
        }.alert(isPresented: Binding<Bool>(
            get: { self.viewModel.alert != nil },
            set: { _ in self.viewModel.alert = nil }
        )) {
            return Alert(
                title: Text(viewModel.alert?.title ?? ""),
                message: Text(viewModel.alert?.message ?? ""),
                dismissButton: Alert.Button.default(Text(viewModel.alert?.actionTitle ?? ""), action: {
                    presentationMode.wrappedValue.dismiss()
                }))
        }
        .buttonStyle(BlueButtonStyle())
    }
}
