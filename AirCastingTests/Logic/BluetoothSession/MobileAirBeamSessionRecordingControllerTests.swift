// Created by Lunar on 17/11/2022.
//

import XCTest
import Resolver
import CoreLocation
import Combine
@testable import AirCasting

final class MobileAirBeamSessionRecordingControllerTests: ACTestCase {
    lazy var sut = MobileAirBeamSessionRecordingController()
    let device = BluetoothDeviceMock(name: "Device", uuid: "123")
    private var measurementsSaver = MeasurementsSavingServiceMock()
    private var storage = MobileSessionStorageMock()
    private var measurementsRecorder =  MeasurementsRecordingServicesMock()
    private var activeSessionProvider = ActiveMobileSessionProvidingServiceMock()
    private var locationTracker = LocationTrackerMock()
    private var btManager = BluetoothConnectionHandlerMock()
    private var configurator = AirBeamConfiguratorMock(device: BluetoothDeviceMock(name: "Device", uuid: "123"))
    
    override func setUp() {
        super.setUp()
        Resolver.test.register { self.measurementsSaver as MeasurementsSavingService }
        Resolver.test.register { self.storage as MobileSessionStorage }
        Resolver.test.register { self.measurementsRecorder as MeasurementsRecordingServices }
        Resolver.test.register { self.activeSessionProvider as ActiveMobileSessionProvidingService }
        Resolver.test.register { self.locationTracker as LocationTracker }
        Resolver.test.register { self.btManager as BluetoothConnectionHandler }
        Resolver.test.register { self.configurator as AirBeamConfigurator }
    }

    func testStartRecording_whenAlreadyRecordingSession_failsToRecordAnotherOne() {
        configurator.fakeResult = .success(())
        sut.startRecording(session: .mobileAirBeamMock, device: device, completion: { _ in })
        sut.startRecording(session: .mobileAirBeamMock, device: device, completion: { result in
            switch result {
            case .success():
                XCTFail("Started recording another session when another session was already being recorded!")
            case .failure(_):
                return
            }
        })
    }
    
    func testStartRecording_configuresABForMobileSession() {
        sut.startRecording(session: .mobileAirBeamMock, device: device, completion: { _ in })
        XCTAssertEqual(configurator.callsHistory, [.configureMobileSession])
    }
    
    func testStartRecording_configurationIsSuccessfull_createsNewSession() throws {
        sut.startRecording(session: .mobileAirBeamMock, device: device, completion: { _ in })
        XCTAssertEqual(measurementsSaver.createSessionCalls, 1)
    }
    
    struct FakeError: Error {}
    
    func testStartRecording_configurationFails_doesntCreateNewSession() throws {
        configurator.fakeResult = .failure(FakeError())
        sut.startRecording(session: .mobileAirBeamMock, device: device, completion: { _ in })
        XCTAssertEqual(measurementsSaver.createSessionCalls, 0)
    }
    
    func testStartRecording_successfullSessionCreationWithLocation_startsLocationTracking() throws {
        sut.startRecording(session: .mobileAirBeamMock, device: device, completion: { _ in })
        XCTAssertEqual(locationTracker.callsHistory, [.start])
    }
    
    func testStartRecording_successfullLocationlessSessionCreation_doesntStartLocationTracking() throws {
        sut.startRecording(session: .mobileAirBeamLocationlessMock, device: device, completion: { _ in })
        XCTAssertEqual(locationTracker.callsHistory, [])
    }
    
    func testStartRecording_successfullSessionCreationWithLocation_setsActiveSession() throws {
        sut.startRecording(session: .mobileAirBeamMock, device: device, completion: { _ in })
        XCTAssertNotNil(activeSessionProvider.activeSession)
    }
    
    func testStartRecording_successfullSessionCreationWithLocation_startsRecordingMeasurements() throws {
        sut.startRecording(session: .mobileAirBeamMock, device: device, completion: { _ in })
        XCTAssertEqual(measurementsRecorder.callsHistory, [.record])
    }
    
    func testStopRecording_whenSessionInBeingRecorded_disconnectsDevice() throws {
        sut.startRecording(session: .mobileAirBeamMock, device: device, completion: { _ in })
        sut.stopRecordingSession(with: Session.mobileAirBeamMock.uuid, databaseChange: { _ in })
        XCTAssertEqual(btManager.disconnectCalls, 1)
    }
    
    func testStopRecording_whenSessionInBeingRecorded_stopsLocationTracking() throws {
        sut.startRecording(session: .mobileAirBeamMock, device: device, completion: { _ in })
        sut.stopRecordingSession(with: Session.mobileAirBeamMock.uuid, databaseChange: { _ in })
        XCTAssertEqual(locationTracker.callsHistory, [.start, .stop])
    }
    
    func testStopRecording_whenSessionInBeingRecorded_clearsActiveSession() throws {
        sut.startRecording(session: .mobileAirBeamMock, device: device, completion: { _ in })
        sut.stopRecordingSession(with: Session.mobileAirBeamMock.uuid, databaseChange: { _ in })
        XCTAssertNil(activeSessionProvider.activeSession)
    }
    
    func testStopRecording_whenSessionInBeingRecorded_stopsRecording() throws {
        sut.startRecording(session: .mobileAirBeamMock, device: device, completion: { _ in })
        sut.stopRecordingSession(with: Session.mobileAirBeamMock.uuid, databaseChange: { _ in })
        XCTAssertEqual(measurementsRecorder.callsHistory, [.record, .stopRecording])
    }
    
    func testResumeRecording_whenSessionIsBeingRecorded_doesntStartRecordingAndCompletesWithFailure() throws {
        sut.startRecording(session: .mobileAirBeamMock, device: device, completion: { _ in })
        sut.resumeRecording(device: device, completion: { _ in })
        XCTAssertEqual(measurementsRecorder.callsHistory, [.record])
    }
    
    func testResumeRecording_whenNoSessionIsBeingRecorded_startsRecordingAndCompletesWithSuccess() throws {
        activeSessionProvider.setActiveSession(session: .mobileAirBeamMock, device: device)
        sut.resumeRecording(device: device, completion: { result in
            switch result {
            case .success():
                return
            case .failure(_):
                XCTFail()
                return
            }
        })
        XCTAssertEqual(measurementsRecorder.callsHistory, [.record])
    }
    
    func testResumeRecording_whenNoSessionIsBeingRecorded_startsLocationTrackingAndCompletesWithSuccess() throws {
        activeSessionProvider.setActiveSession(session: .mobileAirBeamMock, device: device)
        sut.resumeRecording(device: device, completion: { result in
            switch result {
            case .success():
                return
            case .failure(_):
                XCTFail()
                return
            }
        })
        XCTAssertEqual(locationTracker.callsHistory, [.start])
    }
}

class MeasurementsSavingServiceMock: MeasurementsSavingService {
    var createSessionResult: Result<Void, Error> = .success(())
    var createSessionCalls = 0
    
    func handlePeripheralMeasurement(_ measurement: ABMeasurementStream, sessionUUID: SessionUUID, locationless: Bool) {
        
    }
    func createSession(session: Session, device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        createSessionCalls += 1
        completion(createSessionResult)
    }
}

class MeasurementsRecordingServicesMock: MeasurementsRecordingServices {
    enum HistoryItem {
        case record
        case stopRecording
    }
    var callsHistory: [HistoryItem] = []
    
    func record(with device: any BluetoothDevice, completion: @escaping (ABMeasurementStream) -> Void) {
        callsHistory.append(.record)
    }
    func stopRecording() {
        callsHistory.append(.stopRecording)
    }
}

class BluetoothConnectionHandlerMock: BluetoothConnectionHandler {
    var disconnectCalls = 0
    func connect(to device: any BluetoothDevice, timeout: TimeInterval, completion: @escaping BluetoothManager.ConnectionCallback) {}
    func disconnect(from device: any BluetoothDevice) { disconnectCalls += 1}
    func discoverCharacteristics(for device: any BluetoothDevice, timeout: TimeInterval, completion: @escaping BluetoothManager.CharacteristicsDicoveryCallback) {}
}

class AirBeamConfiguratorMock: AirBeamConfigurator {
    private let device: any BluetoothDevice
    enum HistoryItem {
        case configureMobileSession
    }
    
    var callsHistory: [HistoryItem] = []
    var fakeResult: Result<Void, Error> = .success(())
    
    init(device: any BluetoothDevice) {
        self.device = device
    }
    
    func configureMobileSession(location: CLLocationCoordinate2D, completion: @escaping (Result<Void, Error>) -> Void) {
        callsHistory.append(.configureMobileSession)
        completion(fakeResult)
        
    }
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
    var callsHistory: [HistoryItem] = []
    var location: CurrentValueSubject<CLLocation?, Never> = .init(nil)
    func start() {
        callsHistory.append(.start)
    }
    func stop() {
        callsHistory.append(.stop)
    }
}

class ActiveMobileSessionProvidingServiceMock: ActiveMobileSessionProvidingService {
    private(set) var activeSession: MobileSession? = MobileSession(device: BluetoothDeviceMock(name: "Device", uuid: "1234"), session: Session.mobileAirBeamMock)
    
    func setActiveSession(session: Session, device: any BluetoothDevice) {
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
