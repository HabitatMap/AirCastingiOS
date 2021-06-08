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
    @ObservedObject var session: SessionEntity
    @EnvironmentObject private var microphoneManager: MicrophoneManager
    var thresholds: [SensorThreshold]

    var body: some View {
        VStack(alignment: .leading, spacing: 13){
            dateAndTime
            nameLabelAndExpandButton
            if session.deviceType == .MIC {
                HStack {
                    measurementsMic
                    Spacer()
                    //This is a temporary solution for stopping mic session recording until we implement proper session edition menu
                    if microphoneManager.session?.uuid == session.uuid, microphoneManager.isRecording && (session.status == .RECORDING || session.status == .DISCONNETCED) {
                        stopRecordingButton
                    }
                }
            } else {
                ABMeasurementsView(session: session,
                                   thresholds: thresholds)
            }
        }
        .font(Font.moderate(size: 13, weight: .regular))
        .foregroundColor(.aircastingGray)
    }
}

private extension SessionHeaderView {
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
            Text("\(session.type?.description ?? SessionType.unknown("").description), \(session.deviceType?.description ?? "")")
                .font(Font.moderate(size: 13, weight: .regular))
        }
        .foregroundColor(.darkBlue)
    }
    
    var measurementsMic: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Most recent measurement:")
            SingleMeasurementView(streamName: "db",
                                  value: lastMicMeasurement(),
                                  thresholds: thresholds)
        }
    }
    
    var stopRecordingButton: some View {
        Button(action: {
            try! microphoneManager.stopRecording()
        }, label: {
            Text("Stop recording")
                .foregroundColor(.blue)
        })
    }
        
    func lastMicMeasurement() -> Double {
        return session.dbStream?.latestValue ?? 0
    }
}

#if DEBUG
struct SessionHeader_Previews: PreviewProvider {
    static var previews: some View {
        SessionHeaderView(action: {},
                          isExpandButtonNeeded: true,
                          session: SessionEntity.mock,
                          thresholds: [.mock])
        .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
}
#endif
