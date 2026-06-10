// Created by Lunar on 02/12/2021.
//

import Foundation
import Resolver

class SDRestartABViewModel: ObservableObject {

    @Published var presentNextScreen: Bool = false
    let isSDClearProcess: Bool

    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var reconnectGuard: SessionManagingReconnectionController
    private var suppressedDeviceUUID: String?

    init(isSDClearProcess: Bool) {
        self.isSDClearProcess = isSDClearProcess
    }

    /// Called from the view's `.onAppear`. The "Restart your AirBeam" screen
    /// instructs the user to power-cycle the device, which triggers a
    /// CoreBluetooth disconnect. With a mobile recording session still
    /// active on that device the reconnect chain would otherwise resume
    /// recording behind the wizard, leaving the AirBeam in
    /// "already-recording" state by the time the user reaches the
    /// SelectPeripheralView and we attempt the SD-sync connect.
    func onAppear() {
        guard suppressedDeviceUUID == nil else { return }
        guard let uuid = activeSessionProvider.activeSession?.device.uuid else { return }
        reconnectGuard.suppressReconnect(deviceUUID: uuid)
        suppressedDeviceUUID = uuid
    }

    /// Called from the view's `.onDisappear`. The downstream sync /
    /// clear-SD view models add their own suppression for the duration of
    /// their flow, so dropping ours here is safe — the suppression count
    /// is refcounted in `SessionManagingReconnectionController`.
    func onDisappear() {
        guard let uuid = suppressedDeviceUUID else { return }
        reconnectGuard.releaseReconnect(deviceUUID: uuid)
        suppressedDeviceUUID = nil
    }

    func continueSyncFlow() {
       presentNextScreen = true
    }
}
