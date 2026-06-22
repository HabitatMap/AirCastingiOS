// Created by Lunar on 02/11/2022.
//

import Foundation
import Resolver

class SelectPeripheralViewModel: ObservableObject {
    @Injected var btManager: BluetoothScanner
    @Published var isScanning = false
    @Published var airbeams = [any BluetoothDevice]()
    @Published var otherDevices = [any BluetoothDevice]()
    
    func viewAppeared() {
        scan()
    }
    
    func viewDisappeared() {
        btManager.stopScan()
    }
    
    func refreshButtonTapped() {
        scan()
    }
    
    private func scan() {
        isScanning = true
        airbeams = []
        otherDevices = []
        btManager.startScanning(
            scanningWindow: 30,
            onDeviceDiscovered: { device in
                self.addDevice(device)
            },
            onScanningFinished: {
                DispatchQueue.main.async {
                    self.isScanning = false
                }
            })
    }
    
    private func addDevice(_ device: any BluetoothDevice) {
        DispatchQueue.main.async {
            // Case-insensitive: V2 firmware advertises as "airbeammini" lowercase in
            // CBAdvertisementDataLocalNameKey, while CBPeripheral.name (when populated
            // from GAP) tends to be "AirBeamMini" capitalized.
            if device.name?.range(of: "airbeam", options: .caseInsensitive) != nil {
                Self.upsert(device, into: &self.airbeams)
            } else if !(device.name?.isEmpty ?? true) {
                Self.upsert(device, into: &self.otherDevices)
            }
        }
    }

    /// Insert or replace a device by uuid. Replaces when the incoming entry
    /// carries new information (real MAC parsed from the advert, or a different
    /// name) so the UI upgrades from the UUID-suffix fallback to the firmware
    /// `AirBeamMini:<MAC>` name once iOS surfaces the scan response.
    private static func upsert(_ device: any BluetoothDevice, into list: inout [any BluetoothDevice]) {
        if let idx = list.firstIndex(where: { $0.uuid == device.uuid }) {
            let existing = list[idx]
            let incomingIsBetter = (existing.realMacAddress == nil && device.realMacAddress != nil)
                || (existing.name != device.name && device.realMacAddress != nil)
            if incomingIsBetter { list[idx] = device }
        } else {
            list.append(device)
        }
    }
}
