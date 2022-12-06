// Created by Lunar on 16/11/2022.
//

import Foundation

protocol BluetoothScanner {
    func startScanning(scanningWindow: Int,
                       onDeviceDiscovered: @escaping (any BluetoothDevice) -> Void,
                       onScanningFinished: (() -> Void)?)
    func stopScan()
}

extension BluetoothManager: BluetoothScanner {}
