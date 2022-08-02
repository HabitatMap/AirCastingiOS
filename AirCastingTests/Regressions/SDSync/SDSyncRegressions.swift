// Created by Lunar on 12/07/2022.
//

//import XCTest
//import CoreBluetooth
//import Resolver
//import Combine
//import CoreData
//@testable import AirCasting

// swiftlint:disable print_using

//class SDSyncRegressions: ACTestCase {
//    let uuid = UUID()
//    let measurementsCount = 100_000
//    lazy var airBeamServices = AirBeamServices(measurementCount: measurementsCount, uuid: uuid)
//    lazy var uploadServices = UploadFixedSessionService()
//    lazy var fixedServices = FixedSessionUpdatingService()
//    lazy var synchronizer = Synchronizer()
//    lazy var persistence = PersistenceController(inMemory: true)
//    
//    override func setUp() {
//        // Clear Documents and Temp directory
//        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let tempURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
//        try! FileManager.default.clearDirectory(at: documentsURL)
//        try! FileManager.default.clearDirectory(at: tempURL)
//        
//        super.setUp()
//        
//        Resolver.test.register { self.airBeamServices as SDCardAirBeamServices }
//        Resolver.test.register { self.uploadServices as UploadFixedSessionAPIService }
//        Resolver.test.register { self.fixedServices as MeasurementUpdatingService }
//        Resolver.test.register { self.persistence as PersistenceController }
//    }
//    
//    //
//    // Regression source:
//    // https://trello.com/c/VeJ8oOaL
//    // SD sync fails when SD card contains lots of data
//    //
//    func test_whenAirbeamHasLotsOfMeasurementsToSync_theAppCrashes() throws {
//        let controller = SDSyncController()
//        let peripheral = CBPeripheralBuilder.create(withName: "AirBeam3-F")!
//        let exp = expectation(description: "Synchronizaion finishes")
//        print("[TEST] Starting SD sync")
//        controller.syncFromAirbeam(peripheral, progress: { _ in }, completion: { _ in
//            print("[TEST] SD sync finished")
//            exp.fulfill()
//        })
//        wait(for: [exp], timeout: 180)
//        let req = NSFetchRequest<SessionEntity>(entityName: "SessionEntity")
//        print("[TEST] Testing persistence")
//        XCTAssertEqual(try persistence.viewContext.fetch(req).count, measurementsCount)
//    }
//
//    // MARK: Doubles
//    
//    // Main point of this tests - it will act like AirBeam producing a given number of measurement and "sending" them to the subsystem
//
//    class AirBeamServices: SDCardAirBeamServices {
//        private let measurementCount: Int
//        private let uuid: UUID
//        
//        init(measurementCount: Int, uuid: UUID = UUID()) {
//            self.measurementCount = measurementCount
//            self.uuid = uuid
//        }
//        
//        func downloadData(from peripheral: CBPeripheral,
//                          progress: @escaping (SDCardDataChunk) -> Void,
//                          completion: @escaping (Result<SDCardDownloadSummary, Error>) -> Void) {
//            let dateFormatter = DateFormatter(format: "MM/dd/yyyy")
//            let timeFormatter = DateFormatter(format: "HH:mm:ss")
//            // swiftlint:disable airCasting_date
//            let startDate = Date().addingTimeInterval(-Double(measurementCount))
//            // swiftlint:enable airCasting_date
//            for i in 0..<measurementCount {
//                let date = startDate.addingTimeInterval(Double(i))
//                let formattedDate = dateFormatter.string(from: date)
//                let formattedTime = timeFormatter.string(from: date)
//                let measurementString = "\(i),\(uuid.uuidString),\(formattedDate),\(formattedTime),50.21,41.21,8,8,8,8,8,8,8"
//                progress(.init(payload: measurementString, sessionType: .mobile, progress: .init(received: i+1, expected: measurementCount)))
//            }
//            completion(.success(.init(expectedMeasurementsCount: [.mobile: measurementCount, .cellular: 0, .fixed: 0])))
//        }
//        
//        func clearSDCard(of peripheral: CBPeripheral, completion: @escaping (Result<Void, Error>) -> Void) {
//            completion(.success(()))
//        }
//    }
//
//    class UploadFixedSessionService: UploadFixedSessionAPIService {
//        @discardableResult
//        func uploadFixedSession(input: UploadFixedMeasurementsParams, completion: @escaping (Result<APIOutput, Error>) -> Void) -> Cancellable {
//            fatalError("Should not reach this part, this test is MOBILE only")
//        }
//    }
//    
//    class FixedSessionUpdatingService: MeasurementUpdatingService {
//        func start() {
//            fatalError("Should not reach this part, this test is MOBILE only")
//        }
//        
//        func updateAllSessionsMeasurements() {
//            fatalError("Should not reach this part, this test is MOBILE only")
//        }
//        
//        func downloadMeasurements(for sessionUUID: SessionUUID, lastSynced: Date, completion: @escaping () -> Void) {
//            fatalError("Should not reach this part, this test is MOBILE only")
//        }
//    }
//    
//    class Synchronizer: SessionSynchronizer {
//        let syncInProgress: CurrentValueSubject<Bool, Never> = .init(false)
//        func triggerSynchronization(options: SessionSynchronizationOptions, completion: (() -> Void)?) {
//            completion?()
//        }
//        func stopSynchronization() { }
//        var errorStream: SessionSynchronizerErrorStream?
//    }
//}
//
//extension FileManager {
//    func clearDirectory(at url: URL) throws {
//        for file in try contentsOfDirectory(atPath: url.path) {
//            try removeItem(at: url.appendingPathComponent(file))
//        }
//    }
//}
