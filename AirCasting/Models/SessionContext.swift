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
        
        // Save data to app'd database
        let session = Session(context: managedObjectContext)
        session.uuid = sessionUUID
        session.name = sessionName
        session.tags = sessionTags
        session.type = Int16(sessionType.rawValue)
        session.deviceType = Int16(deviceType.rawValue)
        session.startTime = Date()
        
        // TO DO: Add location and date
        let temporaryMockedDate = "19/12/19-02:40:00"
        let mockedLocation = CLLocationCoordinate2D(latitude: 200.0, longitude: 200.0)
        
        if session.type == SessionType.FIXED.rawValue {
            // if session is fixed: create an empty session on server,
            // send AB auth data to connect to web session and data needed to start recording
            
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
            syncSink = CreateSessionApi()
                .createEmptyFixedWifiSession(input: .init(session: params,
                                                          compression: true))
                .sink { (completion) in
                    
                } receiveValue: { [weak self] (output) in
                    guard let peripheral = self?.peripheral,
                          let uuid = session.uuid else { return }
                    
                    // TO DO: Chanage mocked data for WiFi
                    AirBeam3Configurator(peripheral: peripheral).configureFixedWifiSession(uuid: uuid,
                                                                                           location: mockedLocation,
                                                                                           dateString: temporaryMockedDate,
                                                                                           wifiSSID: "toya88804693",
                                                                                           wifiPassword: "07078914")
                }
        } else {
            // if session is mobile: send AB data needed to start recording
            guard let peripheral = self.peripheral else { return }
            AirBeam3Configurator(peripheral: peripheral).configureMobileSession(dateString: temporaryMockedDate,
                                                                                location: mockedLocation)
        }
        // TO DO: change else to else if, add fixed cellular and mic
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
