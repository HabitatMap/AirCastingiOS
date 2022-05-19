// Created by Lunar on 06/05/2022.
//
//

import Foundation
import CoreData
import CoreLocation

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
    public var uuid: SessionUUID! {
        get { SessionUUID(rawValue: value(forKey: "uuid") as? String ?? "") }
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
        [FStream,
         pm1Stream,
         pm2Stream,
         pm10Stream,
         HStream].compactMap { $0 }
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
        let match = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.sensorName?.contains("PM2.5") ?? false
        })
        let pm2Stream = match as? MeasurementStreamEntity
        return pm2Stream
    }
    var pm10Stream: MeasurementStreamEntity? {
        let match = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.sensorName?.contains("PM10") ?? false
        })
        let pm10Stream = match as? MeasurementStreamEntity
        return pm10Stream
    }
    var FStream: MeasurementStreamEntity? {
        let match = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.measurementShortType == "F"
        })
        let FStream = match as? MeasurementStreamEntity
        return FStream
    }
    var HStream: MeasurementStreamEntity? {
        let match = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.measurementShortType == "RH"
        })
        let HStream = match as? MeasurementStreamEntity
        return HStream
    }
    var dbStream: MeasurementStreamEntity? {
        let match = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.measurementShortType == "db"
        })
        let dbStream = match as? MeasurementStreamEntity
        return dbStream
    }
}

extension ExternalSessionEntity: Sessionable {
    var gotDeleted: Bool {
        false
    }
    
    var userInterface: UIStateEntity? {
        get { uiState }
        set { uiState = newValue }
    }
    
    var location: CLLocationCoordinate2D? {
        get {
            guard let lat = value(forKey: "latitude") as? CLLocationDegrees,
                    let lon = value(forKey: "longitude") as? CLLocationDegrees else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        set {
            setValue(newValue?.latitude, forKey: "latitude")
            setValue(newValue?.longitude, forKey: "longitude")
        }
    }
    
    var isFixed: Bool {
        return true
    }
    
    var isExternal: Bool {
        return true
    }
    
    var isActive: Bool {
        return true
    }
}
