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
    var threshold: SensorThreshold
    @Binding var selectedStream: MeasurementStreamEntity?
    
    @State private var shareModal = false
    @State private var deleteModal = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                dateAndTime
                Spacer()
                actionsMenu
            }.sheet(isPresented: $shareModal, content: {
                ShareView()
            })
            .sheet(isPresented: $deleteModal, content: {
                DeleteView(viewModel: DefaultDeleteSessionViewModel(), deleteModal: $deleteModal)
            })
            nameLabelAndExpandButton
            if session.deviceType == .MIC {
                HStack {
                    measurementsMic
                    Spacer()
                    // This is a temporary solution for stopping mic session recording until we implement proper session edition menu
                    if microphoneManager.session?.uuid == session.uuid, microphoneManager.isRecording, session.status == .RECORDING || session.status == .DISCONNETCED {
                        stopRecordingButton
                    }
                }
            } else {
                ABMeasurementsView(session: session,
                                   threshold: threshold,
                                   selectedStream: _selectedStream)
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
            if let dbStream = session.dbStream {
                SingleMeasurementView(stream: dbStream,
                                      value: lastMicMeasurement(),
                                      threshold: threshold,
                                      selectedStream: .constant(dbStream))
            }
        }
    }
    
    var stopRecordingButton: some View {
        Button(action: {
            try! microphoneManager.stopRecording()
        }, label: {
            Text("Stop recording")
                .foregroundColor(.accentColor)
        })
    }
    
    var actionsMenu: some View {
        Menu {
            Button {
                // action here
            } label: {
                Label("Resume recording", systemImage: "repeat")
            }
            
            Button {
                // action here
            } label: {
                Label("Edit session", systemImage: "pencil")
            }
            
            Button {
                shareModal.toggle()
            } label: {
                Label("Share session", systemImage: "square.and.arrow.up")
            }
            
            Button {
                deleteModal.toggle()
            } label: {
                Label("Delete session", systemImage: "xmark.circle")
            }
        } label: {
            EditButtonView()
        }
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
                          threshold: .mock,
                          selectedStream: .constant(nil))
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
}
#endif
