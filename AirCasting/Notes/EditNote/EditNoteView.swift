// Created by Lunar on 16/12/2021.
//
import SwiftUI
import AirCastingStyling

struct EditNoteView<VM: EditNoteViewModel>: View {
    @StateObject var viewModel: VM
    
    var body: some View {
        ScrollView {
            ZStack {
                XMarkButton()
                VStack(alignment: .leading, spacing: 20) {
                    title
                    description
                    noteField
                    if viewModel.shouldShowError {
                        errorMessage(text: Strings.AddNoteView.error)
                    }
                    photo
                    continueButton
                    deleteButton
                    cancelButton
                }
                .padding()
            }
        }
        .background(Color.aircastingBackground.ignoresSafeArea())
    }
}

private extension EditNoteView {
    
    var title: some View {
        Text(Strings.EditNoteView.title)
            .font(Fonts.moderateBoldTitle4)
            .foregroundColor(.darkBlue)
    }
    
    var description: some View {
        Text(Strings.EditNoteView.description)
            .font(Fonts.moderateRegularHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    var noteField: some View {
        createNoteTextField(binding: $viewModel.noteText)
    }
    
    var photo: some View {
        HStack {
            if let url = viewModel.notePhoto {
                DownloadableImage(url: url)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    var continueButton: some View {
        Button {
            viewModel.saveTapped()
        } label: {
            Text(Strings.EditNoteView.saveButton)
                .font(Fonts.muliBoldHeading1)
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    var deleteButton: some View {
        Button {
            viewModel.deleteTapped()
        } label: {
            Text(Strings.EditNoteView.deleteButton)
                .font(Fonts.muliBoldHeading1)
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
}
