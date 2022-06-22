// Created by Lunar on 07/06/2022.
//

import SwiftUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var picture: URL?
    
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
            guard let photoURL = info[.imageURL] as? URL else {
                Log.error("Failed to compress the image")
                return
            }
            DispatchQueue.global().async {
                let fm = FileManager.default
                let destinationDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("NotesPhotos")
                do {
                    if !fm.fileExists(atPath: destinationDirectory.path) {
                        try fm.createDirectory(at: destinationDirectory, withIntermediateDirectories: false)
                    }
                    let filePath = destinationDirectory.appendingPathComponent(UUID().uuidString)
                    try FileManager.default.copyItem(at: photoURL, to: filePath)
                    DispatchQueue.main.async {
                        self.photoPicker.picture = filePath
                    }
                } catch {
                    Log.error("Failed to save photo in documents directory")
                }
            }
            picker.dismiss(animated: true)
        }
    }
}
