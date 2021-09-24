// Created by Lunar on 15/09/2021.
//

import Foundation
import CoreData

class FixedSessionFaker {
    init(context: NSManagedObjectContext) {
        let req: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        req.predicate = NSPredicate(format: "name LIKE %@", "Its complicated")
        var session: SessionEntity!
        if let already = try! context.fetch(req).first {
            session = already
        } else {
            session = SessionEntity(context: context)
            session.type = .fixed
            session.uuid = SessionUUID()
            session.name = "Its complicated"
            session.tags = ""
            session.startTime = Date(timeIntervalSinceReferenceDate: 23443)
            session.endTime = Date(timeIntervalSinceReferenceDate: 2344323)
            session.gotDeleted = false
            session.version = 32
            session.status = .RECORDING
            session.deviceType = .AIRBEAM3

            for i in 0..<5 {
                let stream = MeasurementStreamEntity(context: context)
                stream.gotDeleted = false
                stream.measurementShortType = "S\(i)"
                stream.measurementType = "S\(i)"
                stream.sensorName = "S\(i)"
                stream.sensorPackageName = "S\(i)"
                stream.thresholdHigh = 100
                stream.thresholdLow = 10
                stream.thresholdMedium = 20
                stream.thresholdVeryHigh = 110
                stream.thresholdVeryLow = 0
                stream.unitName = "UNiT"
                stream.unitSymbol = "UNT"
                stream.id = .random(in: 0...999)
                stream.session = session
                session.addToMeasurementStreams(stream)

                let th = SensorThreshold(context: context)
                th.sensorName = "S\(i)"
                th.thresholdLow = 10
                th.thresholdHigh = 100
                th.thresholdMedium = 20
                th.thresholdVeryLow = 0
                th.thresholdVeryHigh = 110
            }

            try! context.save()
        }

        var currId: Int64 = 1
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            for stream in session.allStreams ?? [] {
                let measurement = MeasurementEntity(context: context)
                measurement.id = currId
                measurement.time = Date()
                measurement.value = .random(in: 0...120)
                measurement.location = .init(latitude: 50.049683, longitude: 19.944544)
                stream.addToMeasurements(measurement)
                currId += 1
            }
            try! context.save()
        }
    }
}
