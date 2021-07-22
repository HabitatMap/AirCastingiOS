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
    @EnvironmentObject var networkChecker: NetworkChecker
    @ObservedObject var session: SessionEntity
    @EnvironmentObject private var microphoneManager: MicrophoneManager
    var threshold: SensorThreshold
    @Binding var selectedStream: MeasurementStreamEntity?
    @State private var showingAlert = false
    @State private var showModal = false
    @State private var showModalEdit = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                dateAndTime
                Spacer()
                actionsMenu
            }.sheet(isPresented: $showModal, content: {
                ShareViewModal()
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
            Text(Strings.SessionHeaderView.measurementsMicText)
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
            Text(Strings.SessionHeaderView.stopButton)
                .foregroundColor(.accentColor)
        })
    }
    
    var actionsMenu: some View {
        Menu {
            Button {
                // action here
            } label: {
                Label(Strings.SessionHeaderView.resumeButton, systemImage: "repeat")
            }
            
            Button {
                DispatchQueue.main.async {
                    print(" \(networkChecker.connectionAvailable) NETWORK")
                    networkChecker.connectionAvailable ? showModalEdit.toggle() : showingAlert.toggle()
                }
            } label: {
                Label(Strings.SessionHeaderView.editButton, systemImage: "pencil")
            }
            
            Button {
                showModal.toggle()
            } label: {
                Label(Strings.SessionHeaderView.shareButton, systemImage: "square.and.arrow.up")
            }
            
            Button {
                // action here
            } label: {
                Label(Strings.SessionHeaderView.deleteButton, systemImage: "xmark.circle")
            }
        } label: {
            EditButtonView()
        }.alert(isPresented: $showingAlert) {
            Alert(title: Text(Strings.SessionHeaderView.alertTitle),
                  message: Text(Strings.SessionHeaderView.alertMessage),
                  dismissButton: .default(Text(Strings.SessionHeaderView.confirmAlert)))
        }
        .sheet(isPresented: $showModalEdit) { EditViewModal(showModalEdit: $showModalEdit) }
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
