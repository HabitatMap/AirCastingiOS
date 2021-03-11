//
//  SessionContext.swift
//  AirCasting
//
//  Created by Lunar on 10/03/2021.
//

import Foundation
import CoreBluetooth
import CoreData

class CreateSessionContext: ObservableObject {
    var sessionName: String?
    var sessionTags: String?
    var sessionUUID: String?
    var sessionType: SessionType?
    var peripheral: CBPeripheral?
    //var session: Session?
    var deviceType: DeviceType?
    
    var managedObjectContext: NSManagedObjectContext?
    private var syncSink: Any?
    
    func setupAB() {
        guard let managedObjectContext = managedObjectContext,
              let sessionType = sessionType,
              let deviceType = deviceType else { return }
        
        let session = Session(context: managedObjectContext)
        session.uuid = sessionUUID
        session.name = sessionName
        session.tags = sessionTags
        session.type = Int16(sessionType.rawValue)
        session.deviceType = Int16(deviceType.rawValue)
        session.startTime = Date()
        
        // Create empty session object on backend
        // TO DO : change mocked data (contribute, is_indoor, notes, locaation, end_time)
        
        let params = CreateSessionApi.SessionParams(uuid: session.uuid!,
                                                    type: SessionType(rawValue: session.type)!.toString(),
                                                    title: session.name!,
                                                    tag_list: session.tags ?? "",
                                                    start_time: session.startTime!,
                                                    end_time: session.startTime!,
                                                    contribute: false,
                                                    is_indoor: false,
                                                    notes: [],
                                                    version: 0,
                                                    streams: [:],
                                                    latitude: 200.0,
                                                    longitude: 200.0)
        if session.type == SessionType.FIXED.rawValue {
            syncSink = CreateSessionApi()
                .createEmptyFixedWifiSession(input: .init(session: params,
                                                          compression: true))
                .sink { (completion) in
                    
                } receiveValue: { [weak self] (output) in
                    guard let peripheral = self?.peripheral else { return }
                    AirBeam3Configurator(peripheral: peripheral).configure(session: session,
                                                                           wifiSSID: "toya88804693",
                                                                           wifiPassword: "07078914")
                    // TO DO: Chanage mocked data for WiFi
                }
        } else {
            guard let peripheral = self.peripheral else { return }
            AirBeam3Configurator(peripheral: peripheral).configure(session: session,
                                                                   wifiSSID: "toya88804693",
                                                                   wifiPassword: "07078914")
        }
    }
}

enum SessionType: Int16 {
    case MOBILE = 0
    case FIXED = 1
    
    func toString() -> String {
        switch self {
        case .MOBILE: return "MobileSession"
        case .FIXED: return "FixedSession"
        }
    }
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
