// Created by Lunar on 16/05/2022.
//

import Foundation
import CoreLocation

protocol Sessionable {
    var endTime: Date? { get }
    var gotDeleted: Bool { get }
    var name: String? { get }
    var startTime: Date? { get }
    var userInterface: UIStateEntity? { get }
    var location: CLLocationCoordinate2D? { get }
    var uuid: SessionUUID { get }
    var sortedStreams: [MeasurementStreamEntity] { get }
    var allStreams: [MeasurementStreamEntity] { get }
    var isFixed: Bool { get }
    var isMobile: Bool { get }
    var isExternal: Bool { get }
    var isActive: Bool { get }
}
