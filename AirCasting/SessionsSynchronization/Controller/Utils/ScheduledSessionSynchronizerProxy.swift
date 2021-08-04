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

func prepareFakeShit(cd: PersistenceController) {
    let session = SessionEntity(context: cd.viewContext)
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
    for i in 0..<5 {
        let m = MeasurementStreamEntity(context: cd.viewContext)
        m.gotDeleted = false
        m.measurementShortType = "A\(i)"
        m.measurementType = "M\(i)"
        m.sensorName = "AirBeam 3"
        m.sensorPackageName = "IDK"
        m.thresholdVeryLow = 0
        m.thresholdLow = 20
        m.thresholdMedium = 40
        m.thresholdHigh = 60
        m.thresholdVeryHigh = 70
        m.unitName = "NIT"
        m.unitSymbol = "M"
        for j in 0..<10 {
            let meas = MeasurementEntity(context: cd.viewContext)
            meas.location = CLLocationCoordinate2D(latitude: 50, longitude: 50)
            meas.time = Date(timeIntervalSinceNow: Double(j))
            meas.value = Double((i * 10)+j)
            m.addToMeasurements(meas)
        }
        session.addToMeasurementStreams(m)
    }
    
    for stream in session.allStreams ?? [] {
        let threshold: SensorThreshold = try! cd.viewContext.newOrExisting(sensorName: stream.sensorName ?? "asdasd")
        threshold.thresholdVeryLow = stream.thresholdVeryLow
        threshold.thresholdLow = stream.thresholdLow
        threshold.thresholdMedium = stream.thresholdMedium
        threshold.thresholdHigh = stream.thresholdHigh
        threshold.thresholdVeryHigh = stream.thresholdVeryHigh
    }
    
    
    try! cd.viewContext.save()
}
