// Created by Lunar on 02/08/2021.
//

import CoreBluetooth
import Foundation

enum ProceedToView {
    case AB
    case location
    case bluetooth
    case mobile
}

class ChooseSessionTypeViewModel {
    var locationTracker: LocationTracker
    var bluetoothManager: BluetoothManager

    init(locationTracker: LocationTracker, bluetoothManager: BluetoothManager) {
        self.locationTracker = locationTracker
        self.bluetoothManager = bluetoothManager
    }

    func fixSessionNextStep() -> ProceedToView {
        if locationTracker.locationGranted == .denied {
            return .location
        } else {
            if CBCentralManager.authorization == .notDetermined {
                return .bluetooth
            } else {
                return .AB
            }
        }
    }
    
    func mobileSessionNextStep() -> ProceedToView {
        if locationTracker.locationGranted == .denied {
            return .location
        } else {
            return .mobile
        }
    }
}
