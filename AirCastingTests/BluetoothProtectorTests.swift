import XCTest
import Resolver
import Foundation
@testable import AirCasting

class BluetoothProtectorTests: ACTestCase {
    let databaseSpy = AirBeamDatabaseSpy()
    lazy var sut = BluetoothConnectionProtector()
    
    func test_whenDatabaseAsksForExistingSessions_exclcudeOtherThenNewRecordingStatuses() throws {
        Resolver.test.register { self.databaseSpy as SessionsFetchable }
        
        sut.isAirBeamAvailableForNewConnection(peripheraUUID: "", completion: { _ in })
        
        XCTAssertEqual(databaseSpy.constrainedCalls.count, 1)
        let constraint = try XCTUnwrap(databaseSpy.constrainedCalls.first)
        guard case let .predicate(predicate) = constraint else { XCTFail(); return }
        
        let invalidStatuses: [FakePredicateBlueprint] = [.createPredicateWithExpected(status: -2),
                                                         .createPredicateWithExpected(status: 3),
                                                         .createPredicateWithExpected(status: 5)]
        
        XCTAssertEqual(0, (invalidStatuses as NSArray).filtered(using: predicate).count)
    }
    
    func test_whenDatabaseAsksForExistingSessions_inlcudeOnlyNewRecordingStatuses() throws {
        Resolver.test.register { self.databaseSpy as SessionsFetchable }
        
        sut.isAirBeamAvailableForNewConnection(peripheraUUID: "", completion: { _ in })
        
        XCTAssertEqual(databaseSpy.constrainedCalls.count, 1)
        let constraint = try XCTUnwrap(databaseSpy.constrainedCalls.first)
        guard case let .predicate(predicate) = constraint else { XCTFail(); return }
        
        let correctStatuses: [FakePredicateBlueprint] = [.createPredicateWithExpected(status: 2),
                                                         .createPredicateWithExpected(status: -1),
                                                         .createPredicateWithExpected(status: 0)]
        
        XCTAssertEqual(3, (correctStatuses as NSArray).filtered(using: predicate).count)
    }
    
    func test_whenDatabaseAsksForExistingSessions_requestOnlyABDevices() throws {
        Resolver.test.register { self.databaseSpy as SessionsFetchable }
        
        sut.isAirBeamAvailableForNewConnection(peripheraUUID: "", completion: { _ in })
        
        XCTAssertEqual(databaseSpy.constrainedCalls.count, 1)
        let constraint = try XCTUnwrap(databaseSpy.constrainedCalls.first)
        guard case let .predicate(predicate) = constraint else { XCTFail(); return }
        
        let invalidDeviceType: [FakePredicateBlueprint] = [.init(deviceType: "-1", type: "MobileSession", status: 1, peripheralUUID: ""),
                                                           .init(deviceType: "0", type: "MobileSession", status: 1, peripheralUUID: ""),
                                                           .init(deviceType: "2", type: "MobileSession", status: 1, peripheralUUID: "")]
        
        XCTAssertEqual(0, (invalidDeviceType as NSArray).filtered(using: predicate).count)
    }
    
    func test_whenAsksDatabaseForExistingSession_requestOnlyMobileSessions() throws {
        Resolver.test.register { self.databaseSpy as SessionsFetchable }
        
        sut.isAirBeamAvailableForNewConnection(peripheraUUID: "", completion: { _ in })
        
        XCTAssertEqual(databaseSpy.constrainedCalls.count, 1)
        let constraint = try XCTUnwrap(databaseSpy.constrainedCalls.first)
        guard case let .predicate(predicate) = constraint else { XCTFail(); return }
        
        let invalidSessionType: [FakePredicateBlueprint] = [.init(deviceType: "1", type: SessionType.fixed.rawValue, status: 1, peripheralUUID: ""),
                                                            .init(deviceType: "1", type: "", status: 1, peripheralUUID: ""),
                                                            .init(deviceType: "1", type: "MonileSession", status: 1, peripheralUUID: "")]
        
        XCTAssertEqual(0, (invalidSessionType as NSArray).filtered(using: predicate).count)
    }
    
    func test_whenAsksDatabaseForExistingSession_requestThoseWithMatchingPeripheralUUID() throws {
        Resolver.test.register { self.databaseSpy as SessionsFetchable }
        
        sut.isAirBeamAvailableForNewConnection(peripheraUUID: "112", completion: { _ in })
        
        XCTAssertEqual(databaseSpy.constrainedCalls.count, 1)
        let constraint = try XCTUnwrap(databaseSpy.constrainedCalls.first)
        guard case let .predicate(predicate) = constraint else { XCTFail(); return }
        
        let mixedPeripheralUUID: [FakePredicateBlueprint] = [.init(deviceType: "1", type: SessionType.mobile.rawValue, status: 2, peripheralUUID: "112"),
                                                             .init(deviceType: "1", type:  SessionType.mobile.rawValue, status: 2, peripheralUUID: "112."),
                                                             .init(deviceType: "1", type:  SessionType.mobile.rawValue, status: 2, peripheralUUID: "-112")]
        
        XCTAssertEqual(1, (mixedPeripheralUUID as NSArray).filtered(using: predicate).count)
    }
    
    func test_whenAsksDatabaseForExistingeSession_requestOnlyThoseInStandaloneMode() throws {
        Resolver.test.register { self.databaseSpy as SessionsFetchable }
        
        sut.isAirBeamAvailableForNewConnection(peripheraUUID: "112-911-000", completion: { _ in })
        
        XCTAssertEqual(databaseSpy.constrainedCalls.count, 1)
        let constraint = try XCTUnwrap(databaseSpy.constrainedCalls.first)
        guard case let .predicate(predicate) = constraint else { XCTFail(); return }
        
        let mobileStandaloneSession: FakePredicateBlueprint = .init(deviceType: "1", type: SessionType.mobile.rawValue, status: 2, peripheralUUID: "112-911-000")
        
        XCTAssertEqual(1, ([mobileStandaloneSession] as NSArray).filtered(using: predicate).count)
    }
    
    func test_whenAsksDatabaseForExistingeSession_requestOnlyThoseInConnectedRecordingMode() throws {
        Resolver.test.register { self.databaseSpy as SessionsFetchable }
        
        sut.isAirBeamAvailableForNewConnection(peripheraUUID: "112-911-000", completion: { _ in })
        
        XCTAssertEqual(databaseSpy.constrainedCalls.count, 1)
        let constraint = try XCTUnwrap(databaseSpy.constrainedCalls.first)
        guard case let .predicate(predicate) = constraint else { XCTFail(); return }
        
        let mobileABSessions: [FakePredicateBlueprint] = [.init(deviceType: "1", type: SessionType.mobile.rawValue, status: -1, peripheralUUID: ""),
                                                          .init(deviceType: "1", type: SessionType.mobile.rawValue, status: 0, peripheralUUID: "")]
        
        XCTAssertEqual(2, (mobileABSessions as NSArray).filtered(using: predicate).count)
    }
    
    func testConnectingToAB_whenDataBaseReturnsNoSessions_shouldSucced() {
        let database = AirBeamDatabseStub(toReturn: .success([]))
        Resolver.test.register { database as SessionsFetchable }
        
        sut.isAirBeamAvailableForNewConnection(peripheraUUID: "", completion: { result in
            switch result {
            case .success(_):
                break // This is expected path
            case .failure(let error):
                guard let error = error as? BluetoothConnectionProtector.BluetoothConnectionProtectorError else { XCTFail(); return }
                switch error {
                case .alreadyConnected:
                    XCTFail("When no mobile AB session is ongoing there should be no prevention to record AB.")
                case .readError(_):
                    XCTFail("Unexpected predicate error.")
                }
            }
        })
    }
    
    func testConnectingToAB_whenDatabaseReturnAnySession_shouldFail() {
        let database = AirBeamDatabseStub(toReturn: .success([.any]))
        Resolver.test.register { database as SessionsFetchable }
        
        sut.isAirBeamAvailableForNewConnection(peripheraUUID: .default, completion: { result in
            switch result {
            case .success():
                XCTFail("There should be no possibility to connect to the AirBeam which is recording.")
            case .failure(let error):
                guard let error = error as? BluetoothConnectionProtector.BluetoothConnectionProtectorError else { XCTFail(); return }
                switch error {
                case .alreadyConnected:
                    break // This is expected path
                case .readError(_):
                    XCTFail("Unexpected predicate error.")
                }
            }
        })
    }
    
    func testDatabase_whenFetchFails_completeWithError() {
        struct TestError: Error, Equatable {
            let identifier = UUID()
        }
        let resultError = TestError()
        let database = AirBeamDatabseStub(toReturn: .failure(resultError))
        Resolver.test.register { database as SessionsFetchable }
        
        sut.isAirBeamAvailableForNewConnection(peripheraUUID: .default, completion: { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(let error):
                guard let error = error as? BluetoothConnectionProtector.BluetoothConnectionProtectorError else { XCTFail(); return }
                switch error {
                case .alreadyConnected:
                    XCTFail("When no mobile AB session is ongoing there should be a possibility to record AB.")
                case .readError(let readError):
                    guard let error = readError as? TestError else { XCTFail(); return }
                    XCTAssertEqual(error, resultError)
                }
            }
        })
    }
    
    class AirBeamDatabaseSpy: SessionsFetchable {
        var constrainedCalls: [Database.Constraint] = []
        
        func fetchSessions(constrained: Database.Constraint, completion: @escaping (Result<[Database.Session], Error>) -> Void) {
            constrainedCalls.append(constrained)
            completion(.success([]))
        }
    }
    
    class AirBeamDatabseStub: SessionsFetchable {
        private let toReturn: Result<[Database.Session], Error>
        
        init(toReturn: Result<[Database.Session], Error>) {
            self.toReturn = toReturn
        }
        
        func fetchSessions(constrained: Database.Constraint, completion: @escaping (Result<[Database.Session], Error>) -> Void) {
            return completion(toReturn)
        }
    }
}

fileprivate extension Database.Session {
    static var any: Self {
        Database.Session(uuid: .default,
                         type: .mobile,
                         name: "Testable",
                         deviceType: .AIRBEAM3,
                         location: nil,
                         startTime: nil,
                         contribute: false,
                         deviceId: nil,
                         endTime: nil,
                         followedAt: nil,
                         gotDeleted: false,
                         isIndoor: false,
                         tags: nil,
                         urlLocation: nil,
                         version: nil,
                         measurementStreams: nil,
                         status: .RECORDING,
                         notes: nil,
                         peripheralUUID: "")
    }
}

extension BluetoothProtectorTests {
    @objcMembers class FakeDatabaseSession: NSObject {
        
        var type: SessionType
        var deviceType: DeviceType
        var status: SessionStatus
        var peripheralUUID: String
        
        init(type: SessionType, deviceType: DeviceType, status: SessionStatus, peripheralUUID: String) {
            self.type = type
            self.deviceType = deviceType
            self.status = status
            self.peripheralUUID = peripheralUUID
        }
    }
}

extension BluetoothProtectorTests {
    @objc class FakePredicateBlueprint: NSObject {
        @objc let deviceType: String
        @objc let type: String
        @objc let status: Int
        @objc let peripheralUUID: String
        
        init(deviceType: String, type: String, status: Int, peripheralUUID: String) {
            self.deviceType = deviceType
            self.type = type
            self.status = status
            self.peripheralUUID = peripheralUUID
        }
        
        static func createPredicateWithExpected(status: Int) -> FakePredicateBlueprint {
            .init(deviceType: "1",
                  type: "MobileSession",
                  status: status,
                  peripheralUUID: "")
        }
    }
}
