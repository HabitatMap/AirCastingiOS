// Created by Lunar on 20/01/2022.

import SwiftUI

struct NoteTextView: UIViewRepresentable {
    
    @Binding var text: String
    var placeholder: String
    var font = UIFont.preferredFont(forTextStyle: .body)
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        
        textView.font = font
        textView.autocapitalizationType = .sentences
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = UIColor.aircastingGray.withAlphaComponent(0.05)
        textView.layer.borderColor = UIColor.aircastingGray.withAlphaComponent(0.1).cgColor
        textView.layer.borderWidth = 1
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        text == placeholder ? (uiView.textColor = .lightGray) : (uiView.textColor = .black)
    }
    
    class Coordinator : NSObject, UITextViewDelegate {
        
        var parent: NoteTextView
        
        init(_ uiTextView: NoteTextView) {
            self.parent = uiTextView
        }
        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == .lightGray {
                parent.text = ""
                textView.textColor = .black
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if parent.text == parent.placeholder {
                parent.text = ""
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

func createNoteTextField(binding: Binding<String>) -> some View {
    NoteTextView(text: binding, placeholder: Strings.Commons.note)
        .frame(minWidth: UIScreen.main.bounds.width - 30,
               maxWidth: UIScreen.main.bounds.width - 30,
               minHeight: (UIScreen.main.bounds.height) / 3 < 200 ? (UIScreen.main.bounds.height / 3) : 200,
               maxHeight: 200,
               alignment: .topLeading)
}
