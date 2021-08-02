// Created by Lunar on 02/08/2021.
//

import CoreBluetooth
import Foundation

enum ProceedToView {
    case AB
    case Location
    case Bluetooth
}

class ChooseSessionTypeViewModel: ObservableObject {
    var locationTracker: LocationTracker
    var bluetoothManager: BluetoothManager

    init(locationTracker: LocationTracker, bluetoothManager: BluetoothManager) {
        self.locationTracker = locationTracker
        self.bluetoothManager = bluetoothManager
    }

    func proceedingFixSession() -> ProceedToView {
        if locationTracker.locationGranted == .denied {
            return .Location
        } else {
            if CBCentralManager.authorization == .notDetermined {
                return .Bluetooth
            } else {
                return .AB
            }
        }
    }
}
