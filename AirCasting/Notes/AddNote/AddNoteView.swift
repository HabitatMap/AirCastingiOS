// Created by Lunar on 16/12/2021.
//
import SwiftUI
import AirCastingStyling

struct UserImage: Identifiable {
    var id: Int
    var image: UIImage
    var data: Data
}

struct AddNoteView<VM: AddNoteViewModel>: View {
    @StateObject var viewModel: VM
    @State var pictures: [UserImage] = []
    @State var presentPhotoPicker = false
    
    var body: some View {
        ScrollView {
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
        .sheet(isPresented: $presentPhotoPicker) {
            PhotoPicker(pictures: $pictures)
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
        VStack {
            ForEach(pictures) { picture in
                Image(uiImage: picture.image)
                    .resizable()
                    .scaledToFit()
            }
        }
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

#if DEBUG
struct AddNoteView_Previews: PreviewProvider {
    static var previews: some View {
        AddNoteView(
            viewModel: AddNoteViewModel(sessionUUID: "", withLocation: false, exitRoute: {}),
            pictures: [
                UserImage(
                    id: 1,
                    image: UIImage(named: "message-square")!,
                    data: UIImage(named: "message-square")!.jpegData(compressionQuality: 0.5)!),
                UserImage(
                    id: 2,
                    image: UIImage(named: "message-square")!,
                    data: UIImage(named: "message-square")!.jpegData(compressionQuality: 0.5)!)
            ])
    }
}
#endif
