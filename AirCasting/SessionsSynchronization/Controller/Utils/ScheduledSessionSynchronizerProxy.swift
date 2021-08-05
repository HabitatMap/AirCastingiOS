// Created by Lunar on 16/06/2021.
//

import Foundation
import Combine
// For background tasks we need a `UIApplication`.
// If we find ourselves scheduling stuff into backgrond tasks more often we
// should consider abstrating it away and injecting (don't think this will
// be the case tho)
import class UIKit.UIApplication
import struct UIKit.UIBackgroundTaskIdentifier

/// A  _Proxy_ object wrapping any instance of  a `SessionSynchronizationController` and dispatching its work to a passed `Scheduler`. It also wraps it into a background task.
///
/// Note: For more information about the _Proxy_ pattern please read:
/// - The _Gang of Four_ book
/// - https://refactoring.guru/design-patterns/proxy
final class ScheduledSessionSynchronizerProxy<S: Scheduler>: SessionSynchronizer {
    var errorStream: SessionSynchronizerErrorStream? {
        set { controller.errorStream = newValue }
        get { controller.errorStream }
    }
    
    private let scheduler: S
    private var controller: SessionSynchronizer
    private var cancellables: [AnyCancellable] = []
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    init(controller: SessionSynchronizer, scheduler: S) {
        self.controller = controller
        self.scheduler = scheduler
    }
    
    func triggerSynchronization(completion: (() -> Void)?) {
        scheduler.schedule { [weak self] in
            guard let self = self else { return }
            self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "Session synchronization") {
                self.controller.stopSynchronization()
            }
            self.controller.triggerSynchronization { [ weak self] in
                if let identifier  = self?.backgroundTaskIdentifier {
                    UIApplication.shared.endBackgroundTask(identifier)
                }
            }
        }
    }
    
    func stopSynchronization() {
        scheduler.schedule { [weak self] in
            if let identifier  = self?.backgroundTaskIdentifier {
                UIApplication.shared.endBackgroundTask(identifier)
            }
            self?.controller.stopSynchronization()
        }
    }
}

import CoreLocation



class FakeSessionCreator {
    static let minPossibleMeasurement = 0
    static let maxPossibleMeasurement = 70
    
    static var timer: Timer?
    
    static func createFakeSession(persistenceController: PersistenceController) {
        let context = persistenceController.viewContext
        assert(Thread.isMainThread, "This class will only work when ivoked from the main thread because I'm lazy")
        let session = SessionEntity(context: context)
        session.contribute = false
        session.gotDeleted = false
        session.isIndoor = false
        session.locationless = false
        session.name = "FAKE"
        session.deviceType = .AIRBEAM3
        session.startTime = Date()
        session.tags = ""
        session.version = 1
        session.type = .fixed
        session.uuid = .init(rawValue: UUID().uuidString)
        addMeasurementStreams(to: session)
        for i in 0..<10 {
            appendMeasurement(to: session, date: Date().addingTimeInterval(Double(-i)))
        }
        prepareThresholds(session: session)
        
        timer = .scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            appendMeasurement(to: session, date: nil)
        })
        
        try! context.save()
    }
    
    private static func prepareThresholds(session: SessionEntity) {
        for stream in session.allStreams ?? [] {
            let threshold: SensorThreshold = try! session.managedObjectContext!.newOrExisting(sensorName: stream.sensorName!)
            threshold.thresholdVeryLow = stream.thresholdVeryLow
            threshold.thresholdLow = stream.thresholdLow
            threshold.thresholdMedium = stream.thresholdMedium
            threshold.thresholdHigh = stream.thresholdHigh
            threshold.thresholdVeryHigh = stream.thresholdVeryHigh
        }
    }
    
    private static func addMeasurementStreams(to session: SessionEntity) {
        let context = session.managedObjectContext!
        
        for i in 0..<5 {
            let m = MeasurementStreamEntity(context: context)
            m.gotDeleted = false
            m.id = MeasurementID(i)
            m.measurementShortType = "A\(i)"
            m.measurementType = "M\(i)"
            m.sensorName = "AirBeam 3"
            m.sensorPackageName = "IDK"
            m.thresholdVeryLow = Int32(minPossibleMeasurement)
            m.thresholdLow = 20
            m.thresholdMedium = 40
            m.thresholdHigh = 60
            m.thresholdVeryHigh = Int32(maxPossibleMeasurement)
            m.unitName = "NIT"
            m.unitSymbol = "M"
            session.addToMeasurementStreams(m)
        }
    }
    
    static func appendMeasurement(to session: SessionEntity, date: Date?) {
        let context = session.managedObjectContext!
        for stream in session.allStreams ?? [] {
            let minLong = 19.890; let maxLong = 19.968
            let maxLat = 50.073; let minLat = 50.036
            let measurement = MeasurementEntity(context: context)
            let prevLocation = session.allStreams?.first?.allMeasurements?.last?.location
            measurement.location = CLLocationCoordinate2D(latitude: .random(in: minLat...maxLat), longitude: .random(in: minLong...maxLong)).normalize(against: prevLocation)
            measurement.time = date ?? Date()
            measurement.value = .random(in: Double(minPossibleMeasurement)...Double(maxPossibleMeasurement))
            stream.addToMeasurements(measurement)
            print("[FAKER] Added measurement to \(stream.sensorName): loc: \(measurement.location), val: \(measurement.value), time: \(measurement.time)")
        }
        
    }
}

extension CLLocationCoordinate2D {
    // coordinates are not flat euclidian, but let's roll with that
    func normalize(against origin: CLLocationCoordinate2D?, step: Double = 0.001) -> CLLocationCoordinate2D {
        guard let origin = origin else { return self }
        let x = self.longitude - origin.longitude
        let y = self.latitude - origin.latitude
        
        let length = sqrt(x*x + y*y)
        let normX = x/length
        let normY = y/length
        
        return CLLocationCoordinate2D(latitude: origin.latitude + normX * step, longitude: origin.longitude + normY * step)
    }
}
