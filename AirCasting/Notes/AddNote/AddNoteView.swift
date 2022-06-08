// Created by Lunar on 16/12/2021.
//
import SwiftUI
import AirCastingStyling

struct AddNoteView<VM: AddNoteViewModel>: View {
    @StateObject var viewModel: VM
    @State var picture = UIImage(named: "message-square")!
    @State var presentPhotoPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            title
            description
            addPhotoButton
            noteField
            photo
            continueButton
            cancelButton
        }
        .padding()
        .sheet(isPresented: $presentPhotoPicker) {
            PhotoPicker(picture: $picture)
        }
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
    
    var addPhotoButton: some View {
        Button(action: {
            presentPhotoPicker = true
        }) {
            Text(Strings.AddNoteView.photoButton)
        }
    }
    
    var photo: some View {
        Image(uiImage: picture)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 180)
            .padding()
    }
    
    var noteField: some View {
        createNoteTextField(binding: $viewModel.noteText)
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
