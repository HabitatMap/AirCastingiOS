import Foundation
import NotificationCenter

final class NotificationsManager: ObservableObject {
    
    struct Notification {
        let id: UUID = .init()
        let creationTime: Date = .now
        let title: String
        let body: String
    }
    
    enum NotificationCategory {
        case battery
        case testing
        case lowBattery
        
        var notificationsLimit: Int {
            switch self {
            case .battery: 1
            case .lowBattery: 1
            case .testing: 50
            }
        }
    }
    
    private let notificationCenter = UserNotifications.UNUserNotificationCenter.current()
    private var notifications: [NotificationCategory : [Notification]] = [:]
    
    func send(notification: Notification,
              visability: NotificationVisability = .visible,
              for category: NotificationCategory) {
        
        if let categoryItemNumber = notifications[category]?.count,
           categoryItemNumber >= category.notificationsLimit,
           let firstItem = notifications[category]?.first {
            cancelNotification(stringId: firstItem.id.uuidString)
            removeCancelledNotification(for: firstItem.id, category: category)
        }
        
        let content = createNotificationContent(notification.title,
                                                body: notification.body,
                                                visibility: visability)
        
        let request = createRequest(notification.id, content: content)
        
        requestNotification(request)
        notifications[category, default: []].append(notification)
    }
    
   
    private func cancelNotification(stringId: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [stringId])
    }
    
    private func removeCancelledNotification(for id: UUID, category: NotificationCategory) {
        guard let idxToRemove = (notifications[category]?.firstIndex(where: { $0.id == id })) else {
            Log.error("[Notification service] Cannot remove notification using index, it should be possible")
            return
        }
        notifications[category]?.remove(at: idxToRemove)
    }
    
    private func createNotificationContent(_ title: String, body: String, visibility: NotificationVisability) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let userInfo: [AnyHashable: Any] = [NotificationInfoKeys.visability.rawValue: visibility.rawValue]
        content.title = title
        content.body = body
        content.userInfo = userInfo
        if visibility == .prominent { content.sound = .default }
        return content
    }
    
    private func createRequest(_ id: UUID, content: UNNotificationContent) -> UNNotificationRequest {
        UNNotificationRequest(identifier: id.uuidString,
                              content: content,
                              trigger: nil)
    }
    
    private func requestNotification(_ request: UNNotificationRequest) {
        notificationCenter.add(request) { error in
            if let error = error {
                Log.error("[Notification Service] Cannot request new notification, error: \(error)")
            } else {
                Log.info("[Notification Service] Notification successfully triggered!")
            }
        }
    }
}
