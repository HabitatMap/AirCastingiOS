//
//  SessionHeader.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//
import AirCastingStyling
import SwiftUI

struct SessionHeaderView: View {
    let action: () -> Void
    let isExpandButtonNeeded: Bool
    @Binding var isCollapsed: Bool
    @State var chevronIndicator = "chevron.down"
    @EnvironmentObject var networkChecker: NetworkChecker
    @ObservedObject var session: SessionEntity
    @State private var showingAlert = false
    @State private var showingFinishAlert = false
    @State private var shareModal = false
    @State private var deleteModal = false
    @State private var showModal = false
    @State private var showModalEdit = false
    let sessionStopperFactory: SessionStoppableFactory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                dateAndTime
                    .foregroundColor(Color.aircastingTimeGray)
                Spacer()
                if session.isActive {
                    actionsMenuMobile
                }
            }.sheet(isPresented: $shareModal, content: {
                ShareView(showModal: $showModal)
            })
            .sheet(isPresented: $deleteModal, content: {
                DeleteView(viewModel: DefaultDeleteSessionViewModel(), deleteModal: $deleteModal)
            })
            nameLabelAndExpandButton
        }.onChange(of: isCollapsed, perform: { value in
            isCollapsed ? (chevronIndicator = "chevron.down") :  (chevronIndicator = "chevron.up")
        })
        .font(Font.moderate(size: 13, weight: .regular))
        .foregroundColor(.aircastingGray)
    }
}

private extension SessionHeaderView {
    var dateAndTime: some View {
        adaptTimeAndDate()
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
                        Image(systemName: chevronIndicator)
                            .renderingMode(.original)
                    }
                }
            }
            Text("\(session.type?.description ?? SessionType.unknown("").description): \(session.deviceType?.description ?? "")")
                .font(Font.moderate(size: 13, weight: .regular))
        }
        .foregroundColor(.darkBlue)
    }
    
    var actionsMenuMobile: some View {
        Menu {
            actionsMenuMobileStopButton
        } label: {
            ZStack(alignment: .trailing) {
                EditButtonView()
                Rectangle()
                    .frame(width: 35, height: 25, alignment: .trailing)
                    .opacity(0.0001)
            }
        }.alert(isPresented: $showingFinishAlert) {
            Alert(title: Text(Strings.SessionHeaderView.finishAlertTitle) +
                    Text(session.name ?? Strings.SessionHeaderView.finishAlertTitle_2)
                    +
                    Text(Strings.SessionHeaderView.finishAlertTitle_3),
                  message: Text(Strings.SessionHeaderView.finishAlertMessage_1) +
                    Text(Strings.SessionHeaderView.finishAlertMessage_2) +
                    Text(Strings.SessionHeaderView.finishAlertMessage_3),
                  primaryButton: .default(Text(Strings.SessionHeaderView.finishAlertButton), action: {
                    do {
                        try sessionStopperFactory.getSessionStopper(for: session).stopSession()
                    } catch {
                        Log.info("error when stpoing session - \(error)")
                    }
                  }),
                  secondaryButton: .cancel())
        }
    }
    
    var actionsMenuMobileStopButton: some View {
        Button {
            showingFinishAlert = true
        } label: {
            Label(Strings.SessionHeaderView.stopRecordingButton, systemImage: "stop.circle")
        }
    }
    
    var actionsMenuFixed: some View {
        Menu {
            actionsMenuFixedRepeatButton
            actionsMenuFixedEditButton
            actionsMenuFixedShareButton
            actionsMenuFixedDeleteButton
        } label: {
            ZStack(alignment: .trailing) {
                EditButtonView()
                Rectangle()
                    .frame(width: 35, height: 25, alignment: .trailing)
                    .opacity(0.0001)
            }
        }.alert(isPresented: $showingAlert) {
            Alert(title: Text(Strings.SessionHeaderView.alertTitle),
                  message: Text(Strings.SessionHeaderView.alertMessage),
                  dismissButton: .default(Text(Strings.SessionHeaderView.confirmAlert)))
        }
        .sheet(isPresented: $showModalEdit) { EditViewModal(showModalEdit: $showModalEdit) }
    }
    
    var actionsMenuFixedRepeatButton: some View {
        Button {
            // action here
        } label: {
            Label("resume", systemImage: "repeat")
        }
    }
    
    var actionsMenuFixedEditButton: some View {
        Button {
            DispatchQueue.main.async {
                print(" \(networkChecker.connectionAvailable) NETWORK")
                networkChecker.connectionAvailable ? showModalEdit.toggle() : showingAlert.toggle()
            }
        } label: {
            Label(Strings.SessionHeaderView.editButton, systemImage: "pencil")
        }
    }
    
    var actionsMenuFixedShareButton: some View {
        Button {
            shareModal.toggle()
        } label: {
            Label(Strings.SessionHeaderView.shareButton, systemImage: "square.and.arrow.up")
        }
    }
    
    var actionsMenuFixedDeleteButton: some View {
        Button {
            deleteModal.toggle()
        } label: {
            Label(Strings.SessionHeaderView.deleteButton, systemImage: "xmark.circle")
        }
    }
    
    func adaptTimeAndDate() -> Text {
        let formatter = DateIntervalFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateTemplate = "MM/dd/yyyy HH:mm"
        
        guard let start = session.startTime else { return Text("") }
        let end = session.endTime ?? Date()
 
        let string = formatter.string(from: start, to: end)
        return Text(string)
    }
}

#if DEBUG
struct SessionHeader_Previews: PreviewProvider {
    static var previews: some View {
        SessionHeaderView(action: {},
                          isExpandButtonNeeded: true, isCollapsed: .constant(true),
                          session: SessionEntity.mock,
                          sessionStopperFactory: SessionStoppableFactoryDummy())
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
}
#endif
