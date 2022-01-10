// Created by Lunar on 13/08/2021.
//

import Foundation

//
// Will not be needed when we register `SessionStoppable` using `Resolver`
//
protocol SessionStoppableFactory {
    // It really should not use SessionEntity (probably uuid), but the app is too entangled with it to make it all right at once.
    func getSessionStopper(for: SessionEntity) -> SessionStoppable
}

final class SessionStoppableFactoryDefault: SessionStoppableFactory {
    private let measurementStreamStorage: MeasurementStreamStorage
    private let synchronizer: SessionSynchronizer
    private let bluetoothManager: BluetoothManager
    
    init(measurementStreamStorage: MeasurementStreamStorage, synchronizer: SessionSynchronizer, bluetoothManager: BluetoothManager) {
        self.measurementStreamStorage = measurementStreamStorage
        self.synchronizer = synchronizer
        self.bluetoothManager = bluetoothManager
    }
    
    func getSessionStopper(for session: SessionEntity) -> SessionStoppable {
        let stopper = matchStopper(for: session)
        return SyncTriggeringSesionStopperProxy(stoppable: stopper, synchronizer: synchronizer)
    }
    
    private func matchStopper(for session: SessionEntity) -> SessionStoppable {
        switch session.deviceType {
        case .MIC: return MicrophoneSessionStopper(uuid: session.uuid,
                                                   measurementStreamStorage: measurementStreamStorage)
        case .AIRBEAM3: return StandardSesssionStopper(uuid: session.uuid,
                                                       measurementStreamStorage: measurementStreamStorage,
                                                       bluetoothManager: bluetoothManager)
        case .none: return StandardSesssionStopper(uuid: session.uuid,
                                                   measurementStreamStorage: measurementStreamStorage,
                                                   bluetoothManager: bluetoothManager)
        }
    }
}

struct SessionStoppableFactoryDummy: SessionStoppableFactory {
    private struct Dummy: SessionStoppable {
        func stopSession() throws { }
    }
    
    func getSessionStopper(for: SessionEntity) -> SessionStoppable {
        Dummy()
    }
}
