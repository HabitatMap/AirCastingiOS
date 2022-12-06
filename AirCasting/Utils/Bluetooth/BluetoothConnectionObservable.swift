// Created by Lunar on 16/11/2022.
//

import Foundation

protocol BluetoothConnectionObservable {
    func addConnectionObserver(_ observer: BluetoothConnectionObserver)
    func removeConnectionObserver(_ observer: BluetoothConnectionObserver)
}

extension BluetoothManager: BluetoothConnectionObservable {}
