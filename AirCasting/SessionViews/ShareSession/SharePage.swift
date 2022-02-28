// Created by Lunar on 08/07/2021.
//
import MessageUI
import SwiftUI

struct ActivityViewController: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
    
    let sharingFile: Bool
    var itemToShare: URL
    var servicesToShareItem: [UIActivity]? = nil
    var completion: Callback? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: sharingFile ? [itemToShare] : [context.coordinator], applicationActivities: servicesToShareItem)
        controller.completionWithItemsHandler = completion
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator : NSObject, UIActivityItemSource {
        var parent: ActivityViewController
        
        init(_ parent: ActivityViewController) {
            self.parent = parent
        }
        
        func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
            return ""
        }
        
        /// In email apps, other than Apple native one, the subject is taken/considered as the first line from the message body - which is written in the below func
        func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
            
            switch activityType {
            case UIActivity.ActivityType.copyToPasteboard:
                return parent.itemToShare
            case UIActivity.ActivityType.mail:
                return "\(Strings.SessionShare.sharedEmailText): \(parent.itemToShare)"
            default:
                return """
                        \(Strings.SessionShare.sharedEmailText)
                        
                        \(parent.itemToShare)
                        """
            }
        }
        
        func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
            return "\(Strings.SessionShare.sharedEmailText)"
        }
    }
}
