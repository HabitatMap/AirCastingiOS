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
        
        var notificationsLimit: Int {
            switch self {
            case .battery: 1
            case .testing: 50
            }
        }
    }
    
    /// ℹ️
    /// This function adjusts notification visibility based on the time elapsed since the last notification.
    /// Example: `lastSendedMoreThen` set to 10 means a notification will be sent with the specified visibility
    /// only if there has been a gap of at least 10 hours since the last notification was sent.
    /// The default visibility is set to `visible` if none of the conditions are met.
    enum NotificationConditionalVisability: Hashable {
        case lastSendedLessThen(hours: Int, visability: NotificationVisability)
        case lastSendedMoreThen(hours: Int, visability: NotificationVisability)
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
                                                visability: visability.rawValue)
        
        let request = createRequest(notification.id, content: content)
        
        requestNotification(request)
        notifications[category, default: []].append(notification)
    }
    
    func send(notification: Notification,
              visabilityConditions: Set<NotificationConditionalVisability>,
              for category: NotificationCategory) {
        
        var visabilityDecision: NotificationVisability = .visible
        
        if let latestNotification = notifications[category]?.last,
           let timeDifferenceInHours = Calendar.current.dateComponents([.hour], from: latestNotification.creationTime,
                                                                       to: notification.creationTime).hour {
            
            for condition in visabilityConditions {
                switch condition {
                case .lastSendedLessThen(let hours, let visability):
                    if timeDifferenceInHours < hours {
                        visabilityDecision = visability
                        return
                    }
                case .lastSendedMoreThen(let hours, let visability):
                    if timeDifferenceInHours >= hours {
                        visabilityDecision = visability
                        return
                    }
                }
            }
        }
        
        if let categoryItemNumber = notifications[category]?.count,
           categoryItemNumber >= category.notificationsLimit,
           let firstItem = notifications[category]?.first {
            cancelNotification(stringId: firstItem.id.uuidString)
            removeCancelledNotification(for: firstItem.id, category: category)
        }
        
        let content = createNotificationContent(notification.title,
                                                body: notification.body,
                                                visability: visabilityDecision.rawValue)
        
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
    
    private func createNotificationContent(_ title: String, body: String, visability: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let userInfo: [AnyHashable: Any] = [NotificationInfoKeys.visability.rawValue: visability]
        content.title = title
        content.body = body
        content.userInfo = userInfo
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
