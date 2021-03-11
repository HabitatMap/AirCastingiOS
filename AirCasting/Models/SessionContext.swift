//
//  SessionContext.swift
//  AirCasting
//
//  Created by Lunar on 10/03/2021.
//

import Foundation
import CoreBluetooth

class CreateSessionContext: ObservableObject {
    var sessionUUID: String?
    var sessionType: SessionType?
    var peripheral: CBPeripheral?
    var session: Session?
    var deviceType: DeviceType?
    
    func setupAB() {
        guard let peripheral = peripheral,
              let session = session else { return }
        AirBeam3Configurator(peripheral: peripheral).configure(session: session,
                                                               wifiSSID: "",
                                                               wifiPassword: "")
    }
}

enum SessionType: Int {
    case MOBILE = 0
    case FIXED = 1
}

enum SessionStatus: Int {
    case NEW = -1
    case RECORDING = 0
    case FINISHED = 1
    case DISCONNETCED = 2
}

enum StreamingMethod: Int {
    case CELLULAR = 0
    case WIFI = 1
}

enum DeviceType: Int {
    case MIC = 0
    case AIRBEAM3 = 1
}
