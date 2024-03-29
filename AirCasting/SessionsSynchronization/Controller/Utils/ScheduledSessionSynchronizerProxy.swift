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
final class ScheduledSessionSynchronizerProxy<S: Scheduler>: SessionSynchronizer {
    // This property is meant to be used only by the UI, therefore will always be scheduled on the main thread
    let syncInProgress: CurrentValueSubject<Bool, Never>
    
    var errorStream: SessionSynchronizerErrorStream? {
        get { controller.errorStream }
        set { controller.errorStream = newValue }
    }
    
    private let scheduler: S
    private var controller: SessionSynchronizer
    private var cancellables: [AnyCancellable] = []
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    init(controller: SessionSynchronizer, scheduler: S) {
        self.controller = controller
        self.scheduler = scheduler
        syncInProgress = .init(controller.syncInProgress.value)
        controller.syncInProgress.receive(on: DispatchQueue.main).sink(receiveValue: { self.syncInProgress.value = $0 }).store(in: &cancellables)
    }
    
    func triggerSynchronization(options: SessionSynchronizationOptions, completion: (() -> Void)?) {
        scheduler.schedule { [weak self] in
            guard let self = self else { return }
            self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "Session synchronization") { [weak self] in
                Log.info("Background task expired, stopping synchronization")
                self?.controller.stopSynchronization()
                if let identifier  = self?.backgroundTaskIdentifier {
                    UIApplication.shared.endBackgroundTask(identifier)
                }
            }
            self.controller.triggerSynchronization(options: options) { [ weak self] in
                if let identifier  = self?.backgroundTaskIdentifier {
                    UIApplication.shared.endBackgroundTask(identifier)
                }
                completion?()
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
