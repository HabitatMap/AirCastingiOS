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
            if device.name?.contains("AirBeam") == true {
                guard !self.airbeams.contains(where: { $0.uuid == device.uuid }) else { return }
                self.airbeams.append(device)
            } else if !(device.name?.isEmpty ?? true) {
                guard !self.otherDevices.contains(where: { $0.uuid == device.uuid }) else { return }
                self.otherDevices.append(device)
            }
        }
    }
}
