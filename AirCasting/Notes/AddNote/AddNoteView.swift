// Created by Lunar on 16/12/2021.
//
import SwiftUI
import AirCastingStyling

struct AddNoteView<VM: AddNoteViewModel>: View {
    @StateObject var viewModel: VM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            title
            description
            noteField
            continueButton
            cancelButton
        }
        .padding()
    }
}

private extension AddNoteView {
    
    var title: some View {
        Text(Strings.AddNoteView.title)
            .font(Fonts.boldTitle4)
            .foregroundColor(.darkBlue)
    }
    
    var description: some View {
        Text(Strings.AddNoteView.description)
            .font(Fonts.muliHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    var noteField: some View {
        TextView(text: $viewModel.noteText, placeholder: Strings.Commons.note)
            .frame(minWidth: UIScreen.main.bounds.width - 30,
                   maxWidth: UIScreen.main.bounds.width - 30,
                   minHeight: (UIScreen.main.bounds.height) / 3 < 200 ? (UIScreen.main.bounds.height / 3) : 200,
                   maxHeight: 200,
                   alignment: .topLeading)
    }
    
    var continueButton: some View {
        Button {
            viewModel.continueTapped()
        } label: {
            Text(Strings.AddNoteView.continueButton)
                .bold()
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    var cancelButton: some View {
        Button {
            viewModel.cancelTapped()
        } label: {
            Text(Strings.AddNoteView.cancelButton)
        }
        .buttonStyle(BlueTextButtonStyle())
    }
}
