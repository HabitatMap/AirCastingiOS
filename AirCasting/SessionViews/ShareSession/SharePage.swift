// Created by Lunar on 08/07/2021.
//
import MessageUI
import SwiftUI

struct ActivityViewController: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
    
    var itemToShare: URL
    var servicesToShareItem: [UIActivity]? = nil
    var completion: Callback? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [context.coordinator], applicationActivities: servicesToShareItem)
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
        
        /// In email apps, other then Apple native one, the subject it taken/considered as the first line from the message body - which is writtien in the below func
        func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
            guard activityType == .mail else {
                return """
                        \(Strings.SessionShare.sharedEmailText)
                        
                        \(parent.itemToShare)
                        """
            }
            return "\(Strings.SessionShare.sharedEmailText): \(parent.itemToShare)"
        }
        
        func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
            return "\(Strings.SessionShare.sharedEmailText)"
        }
    }
}
