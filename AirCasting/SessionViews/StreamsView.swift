// Created by Lunar on 29/06/2021.
//

import SwiftUI

struct StreamsView: View {
    
    @Binding var selectedStream: MeasurementStreamEntity?
    @ObservedObject var session: SessionEntity
    var threshold: SensorThreshold
    @EnvironmentObject private var microphoneManager: MicrophoneManager
    let measurementPresentationStyle: MeasurementPresentationStyle
    

    var body: some View {
        if session.deviceType == .MIC {
            HStack {
                measurementsMic
                Spacer()
                //This is a temporary solution for stopping mic session recording until we implement proper session edition menu
                if microphoneManager.session?.uuid == session.uuid, microphoneManager.isRecording && (session.status == .RECORDING || session.status == .DISCONNECTED) {
                    stopRecordingButton
                }
            }
        } else {
            ABMeasurementsView(session: session,
                               threshold: threshold,
                               selectedStream: _selectedStream,
                               measurementPresentationStyle: measurementPresentationStyle)
        }
    }
    
    var measurementsMic: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Most recent measurement:")
                .font(Font.moderate(size: 12))
                .padding(.bottom, 3)
                .padding(.horizontal)
            if let dbStream = session.dbStream {
                SingleMeasurementView(stream: dbStream,
                                      value: lastMicMeasurement(),
                                      threshold: threshold,
                                      selectedStream: .constant(dbStream),
                                      measurementPresentationStyle: measurementPresentationStyle)
            }
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
        #warning("Not sure (really not sure, maybe it's ok, just pointing out) this silent unwrap fail is good here.")
        return session.dbStream?.latestValue ?? 0
    }
}

#if DEBUG
struct StreamsWithMeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        StreamsView(selectedStream: .constant(nil),
                    session: .mock,
                    threshold: .mock,
                    measurementPresentationStyle: .showValues)
    }
}
#endif
