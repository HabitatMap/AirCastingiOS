// Created by Lunar on 24/01/2022.
//

import SwiftUI

struct TextView: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var font = UIFont.preferredFont(forTextStyle: .body)
    var isEditing = false
    
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
        textView.textColor = isEditing ? .black : .lightGray
        textView.addDoneButtonToKeyboard()
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    class Coordinator : NSObject, UITextViewDelegate {
        
        var parent: TextView
        
        init(_ uiTextView: TextView) {
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

extension UITextView {
    func addDoneButtonToKeyboard(){
        let toolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        toolbar.barStyle = .default
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                        target: nil,
                                        action: nil)
        
        let done: UIBarButtonItem = UIBarButtonItem(title: Strings.TextView.doneButton,
                                                    style: .done,
                                                    target: self,
                                                    action: #selector(self.doneButtonTapped))
        
        let items = [flexibleSpace, done]
        toolbar.items = items
        toolbar.sizeToFit()
        
        self.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonTapped(){
        self.resignFirstResponder()
    }
}
