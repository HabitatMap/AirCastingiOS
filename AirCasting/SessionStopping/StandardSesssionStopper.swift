// Created by Lunar on 13/08/2021.
//

import Foundation

class StandardSesssionStopper: SessionStoppable {
    private let uuid: SessionUUID
    private let measurementStreamStorage: MeasurementStreamStorage
    private let bluetoothManager: BluetoothManager
    private let options: FinishSessionOptions
    
    init(uuid: SessionUUID, measurementStreamStorage: MeasurementStreamStorage, bluetoothManager: BluetoothManager, options: FinishSessionOptions) {
        self.uuid = uuid
        self.measurementStreamStorage = measurementStreamStorage
        self.bluetoothManager = bluetoothManager
        self.options = options
    }
    
    func stopSession() {
        Log.verbose("Stopping session with uuid \(uuid.rawValue) using standard session stopper")
        bluetoothManager.finishMobileSession(with: uuid, options: options)
    }
}
