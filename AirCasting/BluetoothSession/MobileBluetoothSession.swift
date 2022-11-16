// Created by Lunar on 16/11/2022.
//

import Foundation
import Resolver

enum MobileSessionState {
    case recording(MobileSession)
    case none
}

protocol MobileBluetoothSession {
    func start(_ session: Session, with device: NewBluetoothManager.BluetoothDevice)
}

class DefaultMobileBluetoothSession: MobileBluetoothSession {
    @Published var state: MobileSessionState = .none
    @Injected private var mobileSessionSaver: MobilePeripheralSessionManager
    @Injected private var locationTracker: LocationTracker
    
    func start(_ session: Session, with device: NewBluetoothManager.BluetoothDevice) {
        
    }
}
