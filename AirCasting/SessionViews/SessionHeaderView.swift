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
    @State private var showingAlert = false
    @State private var showingFinishAlert = false
    @State private var shareModal = false
    @State private var deleteModal = false
    @State private var showModal = false
    @State private var showModalEdit = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                dateAndTime
                Spacer()
                if session.type == .fixed {
                    actionsMenuFixed
                } else if !session.isDormant {
                    actionsMenuMobile
                }
            }.sheet(isPresented: $shareModal, content: {
                ShareView(showModal: $showModal)
            })
                .sheet(isPresented: $deleteModal, content: {
                    DeleteView(viewModel: DefaultDeleteSessionViewModel(), deleteModal: $deleteModal)
                })
            nameLabelAndExpandButton
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
                        Image(systemName: "chevron.down")
                            .renderingMode(.original)
                    }
                }
            }
            Text("\(session.type?.description ?? SessionType.unknown("").description), \(session.deviceType?.description ?? "")")
                .font(Font.moderate(size: 13, weight: .regular))
        }
        .foregroundColor(.darkBlue)
    }
    
    var actionsMenuMobile: some View {
        Menu {
            Button {
                showingFinishAlert = true
            } label: {
                Label(Strings.SessionHeaderView.stopRecordingButton, systemImage: "stop.circle")
            }
        } label: {
            ZStack(alignment: .trailing) {
                EditButtonView()
                Rectangle()
                    .frame(width: 30, height: 20, alignment: .trailing)
                    .opacity(0.0001)
            }
        }.alert(isPresented: $showingFinishAlert) {
            Alert(title: Text(Strings.SessionHeaderView.finishAlertTitle) +
                Text(session.name ?? "this session")
                +
                Text("?"),
                  message: Text(Strings.SessionHeaderView.finishAlertMessage_1) +
                    Text(Strings.SessionHeaderView.finishAlertMessage_2) +
                Text(Strings.SessionHeaderView.finishAlertMessage_3),
                  primaryButton: .default(Text(Strings.SessionHeaderView.finishAlertButton), action: {
                    try! microphoneManager.stopRecording()
                }),
                secondaryButton: .cancel())
        }
    }
    
    var actionsMenuFixed: some View {
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
                shareModal.toggle()
            } label: {
                Label(Strings.SessionHeaderView.shareButton, systemImage: "square.and.arrow.up")
            }
            
            Button {
                deleteModal.toggle()
            } label: {
                Label(Strings.SessionHeaderView.deleteButton, systemImage: "xmark.circle")
            }
        } label: {
            ZStack(alignment: .trailing) {
                EditButtonView()
                Rectangle()
                    .frame(width: 30, height: 20, alignment: .trailing)
                    .opacity(0.0001)
            }
        }.alert(isPresented: $showingAlert) {
            Alert(title: Text(Strings.SessionHeaderView.alertTitle),
                  message: Text(Strings.SessionHeaderView.alertMessage),
                  dismissButton: .default(Text(Strings.SessionHeaderView.confirmAlert)))
        }
        .sheet(isPresented: $showModalEdit) { EditViewModal(showModalEdit: $showModalEdit) }
    }
}

#if DEBUG
struct SessionHeader_Previews: PreviewProvider {
    static var previews: some View {
        SessionHeaderView(action: {},
                          isExpandButtonNeeded: true,
                          session: SessionEntity.mock)
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage(), sessionSynchronizer: DummySessionSynchronizer()))
    }
}
#endif
