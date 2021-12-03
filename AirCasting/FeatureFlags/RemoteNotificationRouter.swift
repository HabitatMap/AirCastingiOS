import Foundation
import UIKit

protocol RemoteNotificationRouter {
    typealias Token = AnyHashable
    typealias WorkFinishedCallback = () -> Void
    typealias NotificationHandler = ([AnyHashable : Any], WorkFinishedCallback) -> Void
    func register(_ handler: @escaping NotificationHandler ) -> Token
    func unregister(token: Token)
}

class DefaultRemoteNotificationRouter: RemoteNotificationRouter {
    static let shared: DefaultRemoteNotificationRouter = {
        DefaultRemoteNotificationRouter()
    }()
    
    private var blocks: [Token: NotificationHandler] = [:]
    private let queue = DispatchQueue(label: "default-remote-notif-router")
    
    private init() { }
    
    func register(_ handler: @escaping NotificationHandler) -> Token {
        let uuid = UUID()
        queue.async {
            self.blocks[uuid] = handler
        }
        return uuid
    }
    
    func unregister(token: Token) {
        assert(blocks.keys.contains(token))
        queue.async {
            self.blocks[token] = nil
        }
    }
    
    func handleSystemNotification(userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let group = DispatchGroup()
        queue.async {
            self.blocks.values.forEach { handler in
                group.enter()
                handler(userInfo) { group.leave() }
            }
        }
        group.notify(queue: queue) {
            completionHandler(.newData)
        }
    }
}
