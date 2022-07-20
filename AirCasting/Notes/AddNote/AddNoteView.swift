// Created by Lunar on 16/12/2021.
//
import SwiftUI
import AirCastingStyling

struct AddNoteView<VM: AddNoteViewModel>: View {
    @StateObject var viewModel: VM
    @State var picture: URL?
    @State var presentPhotoPicker = false
    
    var body: some View {
        ScrollView {
            ZStack {
                XMarkButton()
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
            }
        }
        .background(Color.aircastingBackgroundWhite.ignoresSafeArea())
        .sheet(isPresented: $presentPhotoPicker) {
            PhotoPicker(picture: $picture)
                .ignoresSafeArea(.all, edges: [.bottom])
        }
    }
}

private extension AddNoteView {
    
    var title: some View {
        Text(Strings.AddNoteView.title)
            .font(Fonts.muliHeavyTitle1)
            .foregroundColor(.darkBlue)
    }
    
    var description: some View {
        Text(Strings.AddNoteView.description)
            .font(Fonts.moderateRegularHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    var addPhotoButton: some View {
        Button(action: {
            presentPhotoPicker = true
        }) {
            HStack {
                Image(systemName: "camera")
                    .font(Fonts.moderateRegularHeading2)
                if picture == nil {
                    Text(Strings.AddNoteView.photoButton)
                        .font(Fonts.moderateRegularHeading2)
                } else {
                    Text(Strings.AddNoteView.retakePhotoButton)
                        .font(Fonts.moderateRegularHeading2)
                }
                Spacer()
            }
            .padding()
            .foregroundColor(.aircastingGray)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.aircastingGray.opacity(0.1), lineWidth: 1)
            )
        }
        .background(Color.aircastingGray.opacity(0.05))
    }
    
    var photo: some View {
        VStack {
            if let picture = picture, let image = UIImage(contentsOfFile: picture.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
    }
    
    var noteField: some View {
        createNoteTextField(binding: $viewModel.noteText)
            .font(Fonts.muliRegularHeading3)
    }
    
    var continueButton: some View {
        Button {
            viewModel.continueTapped(selectedPictureURL: picture)
        } label: {
            Text(Strings.AddNoteView.continueButton)
                .font(Fonts.muliBoldHeading1)
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

#if DEBUG
struct AddNoteView_Previews: PreviewProvider {
    static var previews: some View {
        AddNoteView(
            viewModel: AddNoteViewModel(sessionUUID: "", withLocation: false, exitRoute: {}),
            picture: nil
        )
    }
}
#endif
