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
                    photo
                    continueButton
                    deleteButton
                    cancelButton
                }
                .padding()
            }
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
            .font(Fonts.regularHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    var noteField: some View {
        TextView(text: $viewModel.noteText, placeholder: Strings.Commons.note, isEditing: true)
            .frame(minWidth: UIScreen.main.bounds.width - 30,
                   maxWidth: UIScreen.main.bounds.width - 30,
                   minHeight: (UIScreen.main.bounds.height) / 3 < 200 ? (UIScreen.main.bounds.height / 3) : 200,
                   maxHeight: 200,
                   alignment: .topLeading)
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
                .font(Fonts.boldHeading1)
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
}
