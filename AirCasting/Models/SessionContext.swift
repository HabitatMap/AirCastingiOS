//
//  SessionContext.swift
//  AirCasting
//
//  Created by Lunar on 10/03/2021.
//

import Foundation
import CoreBluetooth
import CoreData
import AVFoundation

class CreateSessionContext: ObservableObject {
    private let createSessionService: CreateSessionAPIService
    private let managedObjectContext: NSManagedObjectContext
    var sessionName: String?
    var sessionTags: String?
    var sessionUUID: SessionUUID?
    var sessionType: SessionType?
    var peripheral: CBPeripheral?
    var wifiSSID: String?
    var wifiPassword: String?
    var isIndoor: Bool?
    var startingLocation: CLLocationCoordinate2D?
    var deviceType: DeviceType = DeviceType.AIRBEAM3 // It is set here temporarily to fix bug with fixed sessions


    init(createSessionService: CreateSessionAPIService, managedObjectContext: NSManagedObjectContext) {
        self.createSessionService = createSessionService
        self.managedObjectContext = managedObjectContext
    }

    private var syncSink: Any?
    
    private var locationProvider: LocationProvider?
    private var locationSink: Any?
    
    func obtainCurrentLocation() {
        locationProvider = LocationProvider()
        locationProvider?.requestLocation()
        
        locationSink = locationProvider?.$currentLocation
            .sink(receiveValue: { [weak self] (location) in
                self?.startingLocation = location?.coordinate
            })
    }
    
    func setupAB() {
        guard let sessionType = sessionType,
              let sessionUUID = sessionUUID,
              let startingLocation = startingLocation else { return }
        
        // Save data to app's database
        let session: Session = try! managedObjectContext.newOrExisting(uuid: sessionUUID)
        session.name = sessionName
        session.tags = sessionTags
        session.type = sessionType
        session.deviceType = deviceType
        session.startTime = Date()
        session.longitude = startingLocation.longitude
        session.latitude = startingLocation.latitude
        
        try! managedObjectContext.save()
        
        // TO DO: Replace mocked location and date
        let temporaryMockedDate = "19/12/19-02:40:00"
        
        if session.type == SessionType.fixed {
            // if session is fixed: create an empty session on server,
            // then send AB auth data to connect to web session and data needed to start recording
            
            guard let uuid = session.uuid,
                  let name = session.name,
                  let startTime = session.startTime else {
                #warning("Silent death")
                return
            }
            
            // TO DO : change mocked data (contribute, is_indoor, notes, locaation, end_time)
            let params = CreateSessionApi.SessionParams(uuid: uuid,
                                                        type: .fixed,
                                                        title: name,
                                                        tag_list: session.tags ?? "",
                                                        start_time: startTime,
                                                        end_time: startTime,
                                                        contribute: false,
                                                        is_indoor: false,
                                                        notes: [],
                                                        version: 0,
                                                        streams: [:],
                                                        latitude: startingLocation.latitude,
                                                        longitude: startingLocation.longitude)
            createSessionService.createEmptyFixedWifiSession(input: .init(session: params,
                                                                          compression: true),
                                                             completion: { [weak self] result in
                                                                DispatchQueue.main.async {
                                                                    switch result {
                                                                    case .success(let output):
                                                                        guard let peripheral = self?.peripheral,
                                                                              let ssid = self?.wifiSSID,
                                                                              let password = self?.wifiPassword else {
                                                                            #warning("Silent death")
                                                                            return
                                                                        }
                                                                        AirBeam3Configurator(peripheral: peripheral).configureFixedWifiSession(uuid: uuid,
                                                                                                                                               location: startingLocation,
                                                                                                                                               dateString: temporaryMockedDate,
                                                                                                                                               wifiSSID: ssid,
                                                                                                                                               wifiPassword: password)
                                                                    case .failure(let error):
                                                                        Log.warning("Failed to create fixed Wifi session \(error)")
                                                                        #warning("TODO: Show error")
                                                                    }
                                                                }
                                                             })
        } else {
            // if session is mobile: send AB data needed to start recording
            guard let peripheral = self.peripheral else { return }
            AirBeam3Configurator(peripheral: peripheral).configureMobileSession(dateString: temporaryMockedDate,
                                                                                location: startingLocation)
        }
        #warning("TODO: change else to else if to add fixed cellular and mic")
    }
    
    func startMicrophoneSession(microphoneManager: MicrophoneManager){
        guard let sessionType = sessionType,
//              let deviceType = deviceType,
              let startingLocation = startingLocation else { return }
        
        // Save data to app's database
        let session = Session(context: managedObjectContext)
        session.uuid = sessionUUID
        session.name = sessionName
        session.tags = sessionTags
        session.type = sessionType
        session.deviceType = deviceType
        session.startTime = Date()
        session.longitude = startingLocation.longitude
        session.latitude = startingLocation.latitude
        
        do {
            try microphoneManager.startRecording(session: session)
        } catch {
            assertionFailure("Can't start recording microphone session: \(error)")
        }
    }
    
}

public enum SessionType: RawRepresentable, CustomStringConvertible, Hashable, Codable {
    case mobile
    case fixed
    case unknown(String)

    public init(from decoder: Decoder) throws {
        let singleValue = try decoder.singleValueContainer()
        let rawValue = try singleValue.decode(String.self)
        self.init(rawValue: rawValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    public var rawValue: String {
        switch self {
        case .mobile: return "MobileSession"
        case .fixed: return "FixedSession"
        case .unknown(let rawValue): return rawValue
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "MobileSession": self = .mobile
        case "FixedSession": self = .fixed
        default: self = .unknown(rawValue)
        }
    }

    public var description: String {
        switch self {
        case .mobile: return NSLocalizedString("Mobile", comment: "Mobile user readable localized description")
        case .fixed: return NSLocalizedString("Fixed", comment: "Fixed user readable localized description")
        case .unknown: return NSLocalizedString("Other", comment: "Unknown user readable localized description")
        }
    }
}

public enum SessionStatus: Int {
    case NEW = -1
    case RECORDING = 0
    case FINISHED = 1
    case DISCONNETCED = 2
}

enum StreamingMethod: Int {
    case CELLULAR = 0
    case WIFI = 1
}

public enum DeviceType: Int, CustomStringConvertible {
    case MIC = 0
    case AIRBEAM3 = 1
    
    public var description: String {
        switch self {
        case .MIC: return "Device's Microphone"
        case .AIRBEAM3: return "AirBeam 3"
        }
    }
}
