// Created by Lunar on 11/09/2021.
//

import Foundation
import CoreLocation
import CoreData
import Resolver

protocol SyncingMeasurementsViewModel: ObservableObject {
    var sessionDownloader: MeasurementsDownloadable { get }
    var task: Cancellable? { get }
    var session: SessionEntity { get }
    
    func syncMeasurements() throws
}


final class DefaultSyncingMeasurementsViewModel: SyncingMeasurementsViewModel, ObservableObject {
    
    var sessionDownloader: MeasurementsDownloadable
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    var task: Cancellable?
    var session: SessionEntity
    @Published var showLoadingIndicator = true
    
    init(sessionDownloader: MeasurementsDownloadable, session: SessionEntity) {
        self.sessionDownloader = sessionDownloader
        self.session = session
    }
    
    func syncMeasurements() {
        showLoadingIndicator = true
        
        task = sessionDownloader.downloadSessionWithMeasurement(uuid: session.uuid) { [measurementStreamStorage] result in
            switch result {
            case .success(let data):
                let dataBaseStreams = data.streams.values.map { value in
                    SynchronizationDataConverter().convertDownloadDataToDatabaseStream(data: value)
                }
                let sessionId = self.session.uuid!
                let sessionName = self.session.name
                
                // TODO: Move all this logic to a service/controller
                // https://github.com/HabitatMap/AirCastingiOS/issues/606
                measurementStreamStorage.accessStorage { storage in
                    if let endTime = data.endTime {
                        do {
                            try storage.updateSessionEndTimeWithoutUTCConversion(endTime, for: data.uuid)
                        } catch {
                            Log.error("Failed to save new session end time: \(error)")
                        }
                    }
                    dataBaseStreams.forEach { stream in
                        Log.info("Downloaded \(stream.measurements.count) measurements for \(stream.sensorName)")
                        let sensorName = stream.sensorName
                        do {
                            let streamID = try storage.existingMeasurementStream(sessionId, name: sensorName)
                            stream.measurements.forEach { measurement in
                                let location: CLLocationCoordinate2D? = {
                                    guard let latitude = measurement.latitude,
                                          let longitude = measurement.longitude else { return CLLocationCoordinate2D(latitude: 200, longitude: 200) }
                                    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                }()
                                do {
                                    guard let streamID = streamID else { return }
                                    try storage.addMeasurementValue(measurement.value,
                                                                    at:  location,
                                                                    toStreamWithID: streamID,
                                                                    on: measurement.time)
                                } catch {
                                    Log.info("\(error)")
                                }
                            }
                        } catch {
                            Log.info("failed to get existing streamID for synced measurements from session \(String(describing: sessionName))")
                        }
                        
                        do {
                            try storage.saveThresholdFor(sensorName: stream.sensorName,
                                                         thresholdVeryHigh: Int32(stream.thresholdVeryHigh),
                                                         thresholdHigh: Int32(stream.thresholdHigh),
                                                         thresholdMedium: Int32(stream.thresholdMedium),
                                                         thresholdLow: Int32(stream.thresholdLow),
                                                         thresholdVeryLow: Int32(stream.thresholdVeryLow))
                        } catch {
                            Log.info("\(error)")
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        self.showLoadingIndicator = false
                    }
                }
            case .failure(let error):
                Log.info("\(error)")
            }
        }
    }
}
