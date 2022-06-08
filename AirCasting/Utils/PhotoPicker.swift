// Created by Lunar on 07/06/2022.
//

import SwiftUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var pictures: [UserImage]
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(photoPicker: self)
    }
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        let photoPicker: PhotoPicker
        
        init(photoPicker: PhotoPicker) {
            self.photoPicker = photoPicker
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage {
                guard let data = image.jpegData(compressionQuality: 0.7), let compressedImage = UIImage(data: data) else {
                    return
                }
                photoPicker.pictures.append(.init(id: photoPicker.pictures.count + 1, image: compressedImage, data: data))
            } else {
                Log.error("Failed to load an image")
            }
            picker.dismiss(animated: true)
        }
    }
}
