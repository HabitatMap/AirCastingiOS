// Created by Lunar on 11/09/2021.
//

import Foundation
import CoreLocation
import CoreData

protocol SyncingMeasurementsViewModel: ObservableObject {
    var sessionDownloader: MeasurementsDownloadable { get }
    var measurementStreamStorage: MeasurementStreamStorage? { get }
    var task: Cancellable? { get }
    var session: SessionEntity { get }
    
    func syncMeasurements() throws
}


final class DefaultSyncingMeasurementsViewModel: SyncingMeasurementsViewModel {
    
    var sessionDownloader: MeasurementsDownloadable
    var measurementStreamStorage: MeasurementStreamStorage?
    var task: Cancellable?
    var session: SessionEntity
    @Published var showLoadingIndicator = true
    
    init(measurementStreamStorage: MeasurementStreamStorage?, sessionDownloader: MeasurementsDownloadable, session: SessionEntity) {
        self.sessionDownloader = sessionDownloader
        self.measurementStreamStorage = measurementStreamStorage
        self.session = session
    }
    
    func syncMeasurements() {
        guard let measurementStreamStorage = measurementStreamStorage else { return }
        showLoadingIndicator = true
        
        task = sessionDownloader.downloadSessionWithMeasurement(uuid: session.uuid) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                let dataBaseStreams = data.streams.values.map { value in
                    SynchronizationDataConverter().convertDownloadDataToDatabaseStream(data: value)
                }
                
                let sessionId = self.session.uuid!
                let sessionName = self.session.name
                
                measurementStreamStorage.accessStorage { storage in
                    
                    dataBaseStreams.forEach { stream in
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
                                    guard let streamID = streamID else {
                                        return
                                    }
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
