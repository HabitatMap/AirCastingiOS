// Created by Lunar on 06/05/2022.
//
//

import Foundation
import CoreData

extension ExternalSessionEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExternalSessionEntity> {
        return NSFetchRequest<ExternalSessionEntity>(entityName: "ExternalSessionEntity")
    }
    
    @NSManaged public var endTime: Date?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var provider: String
    @NSManaged public var startTime: Date?
    @NSManaged public var measurementStreams: NSOrderedSet?
    @NSManaged public var uiState: UIStateEntity?
    
    //TODO: Think about this empty string stuff
    public var uuid: SessionUUID {
        get { SessionUUID(rawValue: value(forKey: "uuid") as? String ?? "")! }
        set { setValue(newValue.rawValue, forKey: "uuid") }
    }
    
    public var allStreams: [MeasurementStreamEntity] {
        return (measurementStreams?.array as? [MeasurementStreamEntity]) ?? []
    }
    
    func streamWith(sensorName: String) -> MeasurementStreamEntity? {
        allStreams.first { stream in
            stream.sensorName == sensorName
        }
    }
    
    public var sortedStreams: [MeasurementStreamEntity] {
        let abStreams = [FStream,
         pm1Stream,
         pm2Stream,
         pm10Stream,
         HStream].compactMap { $0 }
        
        return abStreams.isEmpty ? allStreams : abStreams
    }
}

// MARK: Generated accessors for measurementStreams
extension ExternalSessionEntity {
    
    @objc(addMeasurementStreamsObject:)
    @NSManaged public func addToMeasurementStreams(_ value: MeasurementStreamEntity)
    
    @objc(removeMeasurementStreamsObject:)
    @NSManaged public func removeFromMeasurementStreams(_ value: MeasurementStreamEntity)
    
    @objc(addMeasurementStreams:)
    @NSManaged public func addToMeasurementStreams(_ values: NSSet)
    
    @objc(removeMeasurementStreams:)
    @NSManaged public func removeFromMeasurementStreams(_ values: NSSet)
    
}

extension ExternalSessionEntity : Identifiable {
    
}

extension ExternalSessionEntity {
    
    var pm1Stream: MeasurementStreamEntity? {
        let match = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.sensorName == "AirBeam3-PM1" ||
            (stream as? MeasurementStreamEntity)?.sensorName == "AirBeam2-PM1" ||
            (stream as? MeasurementStreamEntity)?.sensorName == "AirBeam1-PM1"
        })
        let pm1Stream = match as? MeasurementStreamEntity
        return pm1Stream
    }
    
    var pm2Stream: MeasurementStreamEntity? {
        streamWithSensorNameContaining("PM2.5")
    }
    
    var pm10Stream: MeasurementStreamEntity? {
        streamWithSensorNameContaining("PM10")
    }
    
    var FStream: MeasurementStreamEntity? {
        streamWithType("F")
    }
    
    var HStream: MeasurementStreamEntity? {
        streamWithType("RH")
    }
    
    var dbStream: MeasurementStreamEntity? {
        streamWithType("db")
    }
    
    private func streamWithType(_ type: String) -> MeasurementStreamEntity? {
        allStreams.first(where: { $0.measurementShortType == type })
    }
    
    private func streamWithSensorNameContaining(_ parameterName: String) -> MeasurementStreamEntity? {
        allStreams.first(where: { $0.sensorName?.contains(parameterName) ?? false })
    }
}
