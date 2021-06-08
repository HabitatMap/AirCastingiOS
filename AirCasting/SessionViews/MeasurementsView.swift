// Created by Lunar on 07/06/2021.
//

import SwiftUI

struct ABMeasurementsView: View {
    
    @ObservedObject var session: SessionEntity
    var thresholds: [SensorThreshold]
    
    var body: some View {
        if let measurements = extractLatestMeasurements() {
            VStack(alignment: .leading, spacing: 5) {
                Text("Most recent measurement:")
                HStack {
                    Group {
                        SingleMeasurementView(streamName: "PM1",
                                              value: measurements.pm1,
                                              thresholds: thresholds)
                        SingleMeasurementView(streamName: "PM2",
                                              value: measurements.pm25,
                                              thresholds: thresholds)
                        SingleMeasurementView(streamName: "PM10",
                                              value: measurements.pm10,
                                              thresholds: thresholds)
                        SingleMeasurementView(streamName: "F",
                                              value: measurements.f,
                                              thresholds: thresholds)
                        SingleMeasurementView(streamName: "RH",
                                              value: measurements.h,
                                              thresholds: thresholds)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 3) {
                Text("Your AirBeam is gathering data.")
                    .font(Font.moderate(size: 14))
                Text("Measurements will appear in 3 minutes.")
                    .font(Font.moderate(size: 12))
            }
            .foregroundColor(.darkBlue)
        }
    }
    
    struct LatestMeasurements {
        let pm1: Double
        let pm25: Double
        let pm10: Double
        let f: Double
        let h: Double
    }
    
    func extractLatestMeasurements() -> LatestMeasurements? {
        let pm1Value = session.pm1Stream?.latestValue ?? 0
        let pm25Value = session.pm2Stream?.latestValue ?? 0
        let pm10Value = session.pm10Stream?.latestValue ?? 0
        let fValue = session.FStream?.latestValue ?? 0
        let hValue = session.HStream?.latestValue ?? 0
        
        #warning("TODO: change logic here (session status)")
        if pm1Value != 0 || pm25Value != 0 || pm10Value != 0 || fValue != 0 || hValue != 0 {
            return LatestMeasurements(pm1: pm1Value,
                                      pm25: pm25Value,
                                      pm10: pm10Value,
                                      f: fValue,
                                      h: hValue)
        } else  {
            return nil
        }
    }
}

struct SingleMeasurementView: View {
    
    let streamName: String
    let value: Double
    var thresholds: [SensorThreshold]
    
    var body: some View {
        VStack(spacing: 3) {
            
            Text(streamName)
                .font(Font.system(size: 13))
            HStack(spacing: 3){
                MeasurementDotView(value: value,
                                   thresholds: thresholdFor(name: streamName))
                Text("\(Int(value))")
                    .font(Font.moderate(size: 14, weight: .regular))
            }
        }
    }
    
    func thresholdFor(name: String) -> SensorThreshold? {
        thresholds.first { $0.sensorName == name }
    }
}
