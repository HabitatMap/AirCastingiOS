// Created by Lunar on 25/07/2022.
//

import Foundation
import Resolver
import Combine

/// A  _Proxy_ object wrapping any instance of  a `SessionSynchronizationController`. It checks if the user settings for syncing only through wifi is on and if there is a wifi connection and then triggers sync if appropriate.
///
/// Note: For more information about the _Proxy_ pattern please read:
/// - The _Gang of Four_ book
/// - https://refactoring.guru/design-patterns/proxy
final class WiFiAwareSessionSynchronizerProxy: SessionSynchronizer {
    @InjectedObject private var userSettings: UserSettings
    @Injected private var networkChecker: NetworkChecker
    lazy var syncInProgress: CurrentValueSubject<Bool, Never> = self.controller.syncInProgress
    private var controller: SessionSynchronizer
    
    var errorStream: SessionSynchronizerErrorStream? {
        get { controller.errorStream }
        set { controller.errorStream = newValue }
    }
    
    init(controller: SessionSynchronizer) {
        self.controller = controller
    }
    
    func triggerSynchronization(options: SessionSynchronizationOptions, completion: (() -> Void)?) {
        guard !userSettings.syncOnlyThroughWifi || networkChecker.isUsingWifi else {
            completion?()
            Log.info("Skipping sync cause of no wifi connection")
            return
        }
        controller.triggerSynchronization(options: options, completion: completion)
    }
    
    func stopSynchronization() {
        controller.stopSynchronization()
    }
}
