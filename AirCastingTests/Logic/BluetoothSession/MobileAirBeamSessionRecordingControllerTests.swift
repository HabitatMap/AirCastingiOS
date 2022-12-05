// Created by Lunar on 17/11/2022.
//

import XCTest
import Resolver
import CoreLocation
import Combine
@testable import AirCasting

final class MobileAirBeamSessionRecordingControllerTests: ACTestCase {
    let sut = MobileAirBeamSessionRecordingController()
    private var measurementsSaver = MeasurementsSavingServiceMock()
    private var storage = MobileSessionStorageMock()
    private var measurementsRecorder =  MeasurementsRecordingServicesMock()
    private var activeSessionProvider = ActiveMobileSessionProvidingServiceMock()
    private var locationTracker = LocationTrackerMock()
    private var btManager = BluetoothConnectionHandlerMock()
//    private var configurator = AirBeamConfiguratorMock(device: <#NewBluetoothManager.BluetoothDevice#>)
    
    override func setUp() {
        super.setUp()
        Resolver.test.register { self.measurementsSaver as MeasurementsSavingService }
        Resolver.test.register { self.storage as MobileSessionStorage }
        Resolver.test.register { self.measurementsRecorder as MeasurementsRecordingServices }
        Resolver.test.register { self.activeSessionProvider as ActiveMobileSessionProvidingService }
        Resolver.test.register { self.locationTracker as LocationTracker }
        Resolver.test.register { self.btManager as BluetoothConnectionHandler }
//        Resolver.test.register { self.configurator as AirBeamConfigurator }
    }

    func testStartRecording_configuresABForMobileSession() throws {
        
    }
    
    func testStartRecording_configurationIsSuccessfull_createsNewSession() throws {
        
    }
    
    func testStartRecording_successfullSessionCreationWithLocation_startsLocationTracking() throws {
        
    }
    
    func testStartRecording_successfullSessionCreationWithLocation_setsActiveSession() throws {
        
    }
    
    func testStartRecording_successfullSessionCreationWithLocation_startsRecordingMeasurements() throws {
        
    }
}

class MeasurementsSavingServiceMock: MeasurementsSavingService {
    func handlePeripheralMeasurement(_ measurement: ABMeasurementStream, sessionUUID: SessionUUID, locationless: Bool) {}
    func createSession(session: Session, device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {}
}

class MeasurementsRecordingServicesMock: MeasurementsRecordingServices {
    func record(with device: NewBluetoothManager.BluetoothDevice, completion: @escaping (ABMeasurementStream) -> Void) {}
    func stopRecording() {}
}

class BluetoothConnectionHandlerMock: BluetoothConnectionHandler {
    func connect(to device: NewBluetoothManager.BluetoothDevice, timeout: TimeInterval, completion: @escaping NewBluetoothManager.ConnectionCallback) {}
    func disconnect(from device: NewBluetoothManager.BluetoothDevice) {}
    func discoverCharacteristics(for device: NewBluetoothManager.BluetoothDevice, timeout: TimeInterval, completion: @escaping NewBluetoothManager.CharacteristicsDicoveryCallback) {}
}

class AirBeamConfiguratorMock: AirBeamConfigurator {
    private let device: NewBluetoothManager.BluetoothDevice
    
    init(device: NewBluetoothManager.BluetoothDevice) {
        self.device = device
    }
    
    func configureMobileSession(location: CLLocationCoordinate2D, completion: @escaping (Result<Void, Error>) -> Void) {}
    func configureSession(uuid: SessionUUID, completion: @escaping (Result<Void, Error>) -> Void) {}
    func configureFixedCellularSession(uuid: SessionUUID,
                                       location: CLLocationCoordinate2D,
                                       date: Date,
                                       completion: @escaping (Result<Void, Error>) -> Void) {}
    func configureFixedWifiSession(uuid: SessionUUID,
                                   location: CLLocationCoordinate2D,
                                   date: Date,
                                   wifiSSID: String,
                                   wifiPassword: String,
                                   completion: @escaping (Result<Void, Error>) -> Void) {}
    func configureSDSync(completion: @escaping (Result<Void, Error>) -> Void) {}
    func clearSDCard(completion: @escaping (Result<Void, Error>) -> Void) {}
}

class LocationTrackerMock: LocationTracker {
    enum HistoryItem {
        case start
        case stop
    }
    var callHistory: [HistoryItem] = []
    var location: CurrentValueSubject<CLLocation?, Never> = .init(nil)
    func start() {
        callHistory.append(.start)
    }
    func stop() {
        callHistory.append(.stop)
    }
}

class ActiveMobileSessionProvidingServiceMock: ActiveMobileSessionProvidingService {
    private(set) var activeSession: MobileSession? = MobileSession(device: .init(name: "Device", uuid: "1234"), session: Session.mobileAirBeamMock)
    
    func setActiveSession(session: Session, device: NewBluetoothManager.BluetoothDevice) {
        activeSession = MobileSession(device: device, session: session)
    }
    
    func clearActiveSession() {
        activeSession = nil
    }
}

class MobileSessionStorageMock: MobileSessionStorage {
    var callHistory: [SessionStatus] = []
    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) {
        callHistory.append(sessionStatus)
    }
    func updateSessionEndtime(_ endTime: Date, for uuid: AirCasting.SessionUUID) { }
}
