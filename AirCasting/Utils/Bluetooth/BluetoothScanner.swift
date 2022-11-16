// Created by Lunar on 16/11/2022.
//

import Foundation

protocol BluetoothScanner {
    func startScanning(scanningWindow: Int,
                       onDeviceDiscovered: @escaping (NewBluetoothManager.BluetoothDevice) -> Void,
                       onScanningFinished: (() -> Void)?)
    func stopScan()
}

extension NewBluetoothManager: BluetoothScanner {}
