// Created by Lunar on 16/06/2021.
//

import Foundation
import Combine
// For background tasks we need a `UIApplication`.
// If we find ourselves scheduling stuff into backgrond tasks more often we
// should consider abstrating it away and injecting (don't think this will
// be the case tho)
import class UIKit.UIApplication
import struct UIKit.UIBackgroundTaskIdentifier

/// A  _Proxy_ object wrapping any instance of  a `SessionSynchronizationController` and dispatching its work to a passed `Scheduler`. It also wraps it into a background task.
///
/// Note: For more information about the _Proxy_ pattern please read:
/// - The _Gang of Four_ book
/// - https://refactoring.guru/design-patterns/proxy
class ScheduledSessionSynchronizerProxy<S: Scheduler>: SessionSynchronizer {
    private let scheduler: S
    private let controller: SessionSynchronizer
    private var cancellables: [AnyCancellable] = []
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    init(controller: SessionSynchronizer, scheduler: S) {
        self.controller = controller
        self.scheduler = scheduler
    }
    
    func triggerSynchronization(completion: (() -> Void)?) {
        scheduler.schedule { [weak self] in
            guard let self = self else { return }
            self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "Session synchronization") {
                self.controller.stopSynchronization()
            }
            self.controller.triggerSynchronization { [ weak self] in
                if let identifier  = self?.backgroundTaskIdentifier {
                    UIApplication.shared.endBackgroundTask(identifier)
                }
            }
        }
    }
    
    func stopSynchronization() {
        scheduler.schedule { [weak self] in
            if let identifier  = self?.backgroundTaskIdentifier {
                UIApplication.shared.endBackgroundTask(identifier)
            }
            self?.controller.stopSynchronization()
        }
    }
}
