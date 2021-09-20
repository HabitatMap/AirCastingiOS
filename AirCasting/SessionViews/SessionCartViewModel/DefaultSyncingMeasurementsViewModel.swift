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
                dataBaseStreams.forEach { stream in
                    stream.measurements.forEach { measurement in
                        let location: CLLocationCoordinate2D? = {
                            guard let latitude = measurement.latitude,
                                  let longitude = measurement.longitude else { return CLLocationCoordinate2D(latitude: 200, longitude: 200) }
                            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        }()
                        guard let streamID = try? measurementStreamStorage.existingMeasurementStream(self.session.uuid, name: stream.sensorName) else {
                            Log.info("failed to get existing streamID for synced measurements from session \(String(describing: self.session.name))")
                            return }
                        try? measurementStreamStorage.addMeasurement(Measurement(time: measurement.time, value: measurement.value, location: location), toStreamWithID: streamID)
                    }
                    try? measurementStreamStorage.saveThresholdFor(sensorName: stream.sensorName,
                                                                   thresholdVeryHigh: Int32(stream.thresholdVeryHigh),
                                                                   thresholdHigh: Int32(stream.thresholdHigh),
                                                                   thresholdMedium: Int32(stream.thresholdMedium),
                                                                   thresholdLow: Int32(stream.thresholdLow),
                                                                   thresholdVeryLow: Int32(stream.thresholdVeryLow))
                    
                    try? measurementStreamStorage.save()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    self.showLoadingIndicator = false
                }
                
            case .failure(let error):
                Log.info("\(error)")
            }
        }
    }
}
