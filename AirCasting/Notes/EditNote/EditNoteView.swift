// Created by Lunar on 16/12/2021.
//
import SwiftUI
import AirCastingStyling

struct EditNoteView<VM: EditNoteViewModel>: View {
    @StateObject var viewModel: VM
    
    var body: some View {
        if #available(iOS 15.0, *) {
            mainBody
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(Strings.SessionCart.keyboardToolbarDoneButton) { hideKeyboard() }
                    }
                }
        } else {
            mainBody
                .onTapGesture { hideKeyboard() }
        }
    }
}

private extension EditNoteView {
    
    var title: some View {
        Text(Strings.EditNoteView.title)
            .font(Fonts.boldTitle4)
            .foregroundColor(.darkBlue)
    }
    
    var description: some View {
        Text(Strings.EditNoteView.description)
            .font(Fonts.muliHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    var noteField: some View {
        createEditNoteTextField(binding: $viewModel.noteText)
    }
    
    var continueButton: some View {
        Button {
            viewModel.saveTapped()
        } label: {
            Text(Strings.EditNoteView.saveButton)
                .bold()
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    var deleteButton: some View {
        Button {
            viewModel.deleteTapped()
        } label: {
            Text(Strings.EditNoteView.deleteButton)
                .bold()
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    var cancelButton: some View {
        Button {
            viewModel.cancelTapped()
        } label: {
            Text(Strings.EditNoteView.cancelButton)
        }
        .buttonStyle(BlueTextButtonStyle())
    }
    
    var mainBody: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                title
                description
                noteField
                continueButton
                deleteButton
                cancelButton
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}
