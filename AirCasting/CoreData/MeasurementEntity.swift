// Created by Lunar on 30/04/2021.
//

import Foundation
import CoreData
import CoreLocation

public typealias MeasurementID = Int64

@objc(MeasurementEntity)
public class MeasurementEntity: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MeasurementEntity> {
        return NSFetchRequest<MeasurementEntity>(entityName: "MeasurementEntity")
    }

    @NSManaged public var averagingWindow: Int

    @NSManaged public var time: Date!
    @NSManaged public var value: Double
    @NSManaged public var measurementStream: MeasurementStreamEntity!


    public var location: CLLocationCoordinate2D? {
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
}
