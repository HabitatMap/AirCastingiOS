// Created by Lunar on 09/12/2021.
//

import Foundation
import CoreLocation

class CSVStreamsWithMeasurements {
    
    private(set) var sessions = Set<SDSession>()
    private(set) var streamsWithMeasurements: [SDStream: [Measurement]] = [:]
    
    private let parser = SDCardMeasurementsParser()
    
    init(fileURL: URL, fileLineReader: FileLineReader) throws {
        try fileLineReader.readLines(of: fileURL, progress: { line in
            switch line {
            case .line(let content):
                let measurementsRow = self.parser.parseMeasurement(lineString: content)
                
                guard let measurements = measurementsRow else { return }
                
                var session = sessions.first(where: { $0.uuid == measurements.sessionUUID })
                if session == nil {
                    // It's a new session.
                    session = SDSession(uuid: measurements.sessionUUID,
                                        lastMeasurementTime: nil)
                    sessions.insert(session!)
                }
                
                self.enqueueForSaving(measurements: measurements, buffer: &streamsWithMeasurements)
            case .endOfFile:
                break
            }
        })
    }
    
    private func enqueueForSaving(measurements: SDCardMeasurementsRow, buffer streamsWithMeasurements: inout [SDStream: [Measurement]]) {
        let location = CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)
        let date = measurements.date
        
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .f, header: .f), default: []]
            .append(Measurement(time: date, value: measurements.f, location: location))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .rh, header: .rh), default: []]
            .append(Measurement(time: date, value: measurements.rh, location: location))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm1, header: .pm1), default: []]
            .append(Measurement(time: date, value: measurements.pm1, location: location))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm2_5, header: .pm2_5), default: []]
            .append(Measurement(time: date, value: measurements.pm2_5, location: location))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm10, header: .pm10), default: []]
            .append(Measurement(time: date, value: measurements.pm10, location: location))
    }
    
}
