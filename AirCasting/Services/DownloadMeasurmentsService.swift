//
//  DownloadMeasurmentsService.swift
//  AirCasting
//
//  Created by Lunar on 25/03/2021.
//

import Foundation
import CoreData

class DownloadMeasurementsService: ObservableObject {
    
    var timer = Timer.publish(every: 60, on: .current, in: .common).autoconnect()
    var timerSink: Any?
    private var sink: Any?
    var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    
    func start() {
        timerSink = timer.sink { [weak self] (_) in
            self?.update()
        }
    }
    
    private func update() {
        let uuid = UUID(uuidString: "fcb242f0-fdba-4c9b-943e-51adff1aebac")!
        let syncDate = Date().addingTimeInterval(-8000)
        sink = FixedSession
            .getFixedMeasurement(uuid: uuid,
                                 lastSync: syncDate)
            .sink { (completion) in
                switch completion {
                case .finished:
                    print("sucess")
                case .failure(let error):
                    print("ERROR: \(error)")
                }
            } receiveValue: { [weak self] (fixedMeasurementOutput) in
                guard let self = self else { return }
                
                // Fetch session by id from Core Data
                let fetchRequest = NSFetchRequest<Session>(entityName: "Session")
                fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid.uuidString.lowercased())
                let results = try! self.context.fetch(fetchRequest)
                guard let session = results.first else {
                    return
                }
                
                self.updateSessionsParams(session: session, output: fixedMeasurementOutput)
                
                try! self.context.save()
                print("Yay! UPDATED SESSION! :D ")
            }
    }
    
    func updateSessionsParams(session: Session, output: FixedSession.FixedMeasurementOutput) {
        let dateFormatter = ISO8601DateFormatter()
        session.uuid = output.uuid
        session.type = SessionType.from(string: output.type)?.rawValue ?? -1

        session.name = output.title
        session.tags  = output.tag_list
        session.startTime  = dateFormatter.date(from: output.start_time)
        session.endTime  = dateFormatter.date(from: output.end_time)
        session.version = Int16(output.version)

        for (_, streamOutput) in output.streams {
            let stream = MeasurementStream(context: self.context)
            stream.sensorName = streamOutput.sensor_name
            stream.sensorPackageName = streamOutput.sensor_package_name
            stream.measurementType = streamOutput.measurement_type
            stream.measurementShortType = streamOutput.measurement_short_type
            stream.unitName = streamOutput.unit_name
            stream.unitSymbol = streamOutput.unit_symbol
            stream.thresholdVeryLow = Int32(streamOutput.threshold_very_low)
            stream.thresholdLow = Int32(streamOutput.threshold_low)
            stream.thresholdMedium = Int32(streamOutput.threshold_medium)
            stream.thresholdHigh = Int32(streamOutput.threshold_high)
            stream.thresholdVeryHigh = Int32(streamOutput.threshold_very_high)
            stream.gotDeleted = streamOutput.deleted ?? false

            //                            // Save starting thresholds
            //                            let thresholds = SensorThreshold(context: context)
            //                            thresholds.sensorName = streamOutput.sensor_name
            //                            thresholds.thresholdVeryLow = Int32(streamOutput.threshold_very_low)
            //                            thresholds.thresholdLow = Int32(streamOutput.threshold_low)
            //                            thresholds.thresholdMedium = Int32(streamOutput.threshold_medium)
            //                            thresholds.thresholdHigh = Int32(streamOutput.threshold_high)
            //                            thresholds.thresholdVeryHigh = Int32(streamOutput.threshold_very_high)

            for measurement in streamOutput.measurements {
                let newMeasaurement = Measurement(context: self.context)
                newMeasaurement.value = Double(measurement.measured_value)
                newMeasaurement.latitude = Double(measurement.latitude)
                newMeasaurement.longitude = Double(measurement.longitude)
                newMeasaurement.time = dateFormatter.date(from: measurement.time)
            }
            session.addToMeasurementStreams(stream)
        }

    }
}
