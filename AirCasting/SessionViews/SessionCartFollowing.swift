// Created by Lunar on 29/07/2021.
//

import Foundation

protocol SessionCartFollowing {
    var measurementStreamStorage: MeasurementStreamStorage { get }
    func makeFollowing(for session: SessionEntity)
    func makeNotFollowing(for session: SessionEntity)
}
