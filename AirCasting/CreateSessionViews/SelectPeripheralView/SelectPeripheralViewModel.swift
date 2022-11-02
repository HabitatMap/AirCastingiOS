// Created by Lunar on 02/11/2022.
//

import Foundation
import Resolver
import CoreBluetooth // Delete when we figure out exactly why authorization is checked here

class SelectPeripheralViewModel: ObservableObject {
    @Injected var btManager: NewBluetoothManager
    @Published var isScanning = false
    @Published var airbeams = [NewBluetoothManager.BluetoothDevice]()
    @Published var otherDevices = [NewBluetoothManager.BluetoothDevice]()
    
    func viewAppeared() {
        if CBCentralManager.authorization == .allowedAlways {
            btManager.forceBluetoothPermissionPopup()
            scan()
        }
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
    
    private func addDevice(_ device: NewBluetoothManager.BluetoothDevice) {
        DispatchQueue.main.async {
            if device.name?.contains("AirBeam") == true {
                guard !self.airbeams.contains(device) else { return }
                self.airbeams.append(device)
            } else if !(device.name?.isEmpty ?? true) {
                guard !self.otherDevices.contains(device) else { return }
                self.otherDevices.append(device)
            }
        }
    }
}
