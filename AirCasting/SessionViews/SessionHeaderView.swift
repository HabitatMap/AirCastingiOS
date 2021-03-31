//
//  SessionHeader.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct SessionHeaderView: View {
    
    let action: () -> Void
    let isExpandButtonNeeded: Bool
    let session: Session
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13){
            dateAndTime
            nameLabelAndExpandButton
            measurements
        }
        .font(Font.moderate(size: 13, weight: .regular))
        .foregroundColor(.aircastingGray)
    }
    
    var dateAndTime: some View {
        guard let start = session.startTime else {
            return Text("")
        }
        let end = session.endTime ?? Date()
        
        let formatter = DateIntervalFormatter()
        
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        let string = DateIntervalFormatter().string(from: start, to: end)
        return Text(string)
    }
    
    var nameLabelAndExpandButton: some View {
        
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(session.name ?? "")
                    .font(Font.moderate(size: 18, weight: .bold))
                Spacer()
                if isExpandButtonNeeded {
                    Button(action: {
                        action()
                    }) {
                        Image("expandButtonIcon")
                            .renderingMode(.original)
                    }
                }
            }
            Text("\(showSessionType()), \(session.deviceTypeEnum.toString())")
                .font(Font.moderate(size: 13, weight: .regular))
        }
        .foregroundColor(.darkBlue)
    }
    
    var measurementsTitle: some View {
        Text("Most recent measurement:")
    }
        
    var measurements: some View {
        Group {
            if let measurements = extractLatestMeasurements() {
                VStack {
                    measurementsTitle
                    HStack {
                        Group {
                            singleMeasurement(name: "PM1", value: Int(measurements.pm1))
                            singleMeasurement(name: "PM2", value: Int(measurements.pm25))
                            singleMeasurement(name: "PM10", value: Int(measurements.pm10))
                            singleMeasurement(name: "F", value: Int(measurements.f))
                            singleMeasurement(name: "RH", value: Int(measurements.h))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your AirBeam is gathering data.")
                        .font(Font.moderate(size: 14))
                    Text("Measaurements will appear in 3 minutes.")
                        .font(Font.moderate(size: 12))
                }
                .foregroundColor(.darkBlue)
            }
        }
    }
    
    func singleMeasurement(name: String, value: Int) -> some View {
        VStack(spacing: 3) {
            Text(name)
                .font(Font.system(size: 13))
            HStack(spacing: 3){
                Color.green
                    .clipShape(Circle())
                    .frame(width: 5, height: 5)
                Text("\(value)")
                    .font(Font.moderate(size: 14, weight: .regular))
            }
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
    func showSessionType() -> String {
        if session.type == SessionType.FIXED.rawValue {
            return "Fixed"
        } else {
            return "Mobile"
        }
    }
    
}

struct SessionHeader_Previews: PreviewProvider {
    static var previews: some View {
        SessionHeaderView(action: {},
                          isExpandButtonNeeded: true,
                          session: Session.mock)
    }
}




extension Session {
    
    var deviceTypeEnum: DeviceType {
        DeviceType(rawValue: Int(deviceType))!
    }
    
}
