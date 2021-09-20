// Created by Lunar on 15/09/2021.
//

import Foundation

protocol MeasurementsDownloadable {
    func downloadSessionWithMeasurement(uuid: SessionUUID, completion: @escaping (Result<SessionsSynchronization.SessionDownstreamData, Error>) -> Void) -> Cancellable
}
