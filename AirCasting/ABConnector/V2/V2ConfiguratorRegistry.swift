// Created by Lunar on 30/04/2026.
//

import Foundation

/// Holds one `AirBeamMiniV2Configurator` per device UUID for the lifetime of the app
/// session. Needed because state (response dispatcher, status cache, hourly timer)
/// must persist across the multiple Resolver.resolve sites that touch the V2 path
/// (ReconnectionController, ConnectingABViewModel, BluetoothSessionRecordingController).
final class V2ConfiguratorRegistry {
    private var cache: [String: AirBeamMiniV2Configurator] = [:]
    private let lock = NSLock()

    func configurator(for device: any BluetoothDevice) -> AirBeamMiniV2Configurator {
        lock.lock(); defer { lock.unlock() }
        if let existing = cache[device.uuid] { return existing }
        let new = AirBeamMiniV2Configurator(device: device)
        cache[device.uuid] = new
        return new
    }

    func release(deviceUUID: String) {
        lock.lock(); defer { lock.unlock() }
        cache[deviceUUID]?.teardown()
        cache.removeValue(forKey: deviceUUID)
    }
}
