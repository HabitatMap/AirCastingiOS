// Created by Lunar on 02/12/2021.
//

import Foundation
import Combine
import Resolver

class SDSyncRootViewModel: ObservableObject {

    @Published var backendSyncCompleted: Bool = false
    @Injected private var sessionSynchronizer: SessionSynchronizer
    @Injected private var urlProvider: URLProvider
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var reconnectGuard: SessionManagingReconnectionController

    // Wizard-wide reconnect suppression. The SD sync flow involves a
    // user-driven AB power-cycle (SDRestartABView) plus the wizard's own
    // explicit connect/disconnect cycles (SDSyncViewModel, ClearingSDCard).
    // Any disconnect along the way would otherwise re-trigger the
    // mobile-session auto-reconnect chain in the background, which races
    // the wizard's own BLE calls (stale CBCharacteristic pointers ->
    // CoreBluetooth malloc abort) or silently resumes recording behind
    // the SDSyncCompleteView. Suppressing for the lifetime of this view
    // model (== lifetime of the SD sync fullScreenCover) closes the gaps
    // between the per-screen suppressions that nested view models add.
    private var suppressedDeviceUUID: String?

    init() {
        if let uuid = activeSessionProvider.activeSession?.device.uuid {
            reconnectGuard.suppressReconnect(deviceUUID: uuid)
            suppressedDeviceUUID = uuid
        }
    }

    deinit {
        if let uuid = suppressedDeviceUUID {
            reconnectGuard.releaseReconnect(deviceUUID: uuid)
        }
    }
    
    func executeBackendSync() {
        guard !sessionSynchronizer.syncInProgress.value else {
            onCurrentSyncEnd { self.startBackendSync() }
            return
        }
        startBackendSync()
    }
    
    private func startBackendSync() {
        sessionSynchronizer.triggerSynchronization() {
            DispatchQueue.main.async {
                self.backendSyncCompleted = true
            }
        }
    }
    
    private func onCurrentSyncEnd(_ completion: @escaping () -> Void) {
        guard sessionSynchronizer.syncInProgress.value else { completion(); return }
        var cancellable: AnyCancellable?
        cancellable = sessionSynchronizer.syncInProgress.sink { syncInProgress in
            guard !syncInProgress else { return }
            completion()
            cancellable?.cancel()
        }
    }
}
