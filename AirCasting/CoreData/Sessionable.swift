// Created by Lunar on 16/05/2022.
//

import Foundation
import CoreLocation

protocol Sessionable {
    var contribute: Bool { get }
    var deviceId: String? { get }
    var endTime: Date? { get }
    var followedAt: Date? { get }
    var gotDeleted: Bool { get }
    var isIndoor: Bool { get }
    var locationless: Bool { get }
    var name: String? { get }
    var startTime: Date? { get }
    var tags: String? { get }
    var urlLocation: String? { get }
    var version: Int16 { get }
    var changesCount: Int32 { get }
    var rowOrder: Int64 { get }
    var userInterface: UIStateEntity? { get }
    var measurementStreams: NSOrderedSet? { get }
    var notes: NSOrderedSet? { get }
    var localID: SessionEntityLocalID { get }
    var location: CLLocationCoordinate2D? { get }
    var status: SessionStatus? { get }
    var uuid: SessionUUID! { get }
    var deviceType: DeviceType? { get }
    var type: SessionType! { get }
    var sortedStreams: [MeasurementStreamEntity] { get }
    var allStreams: [MeasurementStreamEntity] { get }
    var lastMeasurementTime: Date? { get }
    var sensorPackageName: String { get }
    func streamWith(sensorName: String) -> MeasurementStreamEntity?
    var isFixed: Bool { get }
    var isMobile: Bool { get }
    var isExternal: Bool { get }
    var isActive: Bool { get }
}
