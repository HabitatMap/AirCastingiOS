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
            // As long as we get session.deviceType = nil we should handle somehow showing those devices which were used to record
            // [|(-)   (-)|]    |-------------------|
            //  |   ___   |  -- | You, do something |
            //  |_________|     |-------------------|
            // so the idea at leat for now is this below
            if session.type?.description == "Fixed" {
                Text("\(session.type?.description ?? SessionType.unknown("").description): AirBeam3")
                    .font(Font.moderate(size: 13, weight: .regular))
            } else if session.type?.description == "Mobile" {
                if session.allStreams!.count > 1 {
                    Text("\(session.type?.description ?? SessionType.unknown("").description): AirBeam3")
                        .font(Font.moderate(size: 13, weight: .regular))
                } else {
                    Text("\(session.type?.description ?? SessionType.unknown("").description): Phone Mic")
                        .font(Font.moderate(size: 13, weight: .regular))
                }
            } else {
                Text(session.deviceType?.description ?? "")
                    .font(Font.moderate(size: 13, weight: .regular))
            }
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
        var fullDate = ""
        var endDate = ""
        
        guard let start = session.startTime else { return Text("") }
        let end = session.endTime ?? Date()
        let string = DateIntervalFormatter().string(from: start, to: end)
        // Purpose of this is to use 24h format all the time (no matter system settings)
        if TimeConverter.is24Hour() {
            // We are checking if user system settings is set to be 24h format
                // if so, no additional change is needed
            let replacedString = string.replacingOccurrences(of: "—", with: "-")
            return Text(replacedString)
        } else {
            if string.contains("–") {
                // containing "-" mean that the session has start and end date
                let time = string.components(separatedBy: "–")
                var timeLast = time.last
                if (timeLast!.contains("/")) {
                    // some of the sessions are being recorded for few days which results in big date format
                    // ---> 17/08/2021, 17:59-10/09/2021, 5:16
                    endDate = (time.last?.components(separatedBy: ",").first)!
                    timeLast = time.last?.components(separatedBy: ",").last
                }
                
                let endTime12 = timeLast!.trimmingCharacters(in: .whitespaces)
            
                let last = time.first!
                let time2 = last.components(separatedBy: ",")
                fullDate = time2.first!
                var startTime12 = time2.last?.trimmingCharacters(in: .whitespaces)
                
                if !(startTime12!.contains("PM") || startTime12!.contains("AM")) {
                    // to convert .AM || .PM time, we need to ensure that is has always the right ending
                    // when session is short, sometimes it results in time formatting like this -> 18:00-19:00 PM
                    // the purpose is to add .PM to the 18:00 in this example
                    (endTime12.contains("PM")) ? startTime12?.append(" PM") : startTime12?.append(" AM")
                }
                if endDate == "" {
                    // the case where only one date is handled (one day session)
                    // needed format then ---> 17/08/2021, 17:59-18:16
                    fullDate.append(", \(TimeConverter.timeConversion24(time12: startTime12!))-\(TimeConverter.timeConversion24(time12: endTime12))")
                } else {
                    // the case where session is recorder at least through two days
                    // needed format then ---> 17/08/2021, 17:59-10/09/2021, 5:16
                    fullDate.append(", \(TimeConverter.timeConversion24(time12: startTime12!))-\(endDate), \(TimeConverter.timeConversion24(time12: endTime12))")
                }
            } else {
                // the case where session has only date and start time
                // needed format then ---> 17/08/2021, 5:16
                let time2 = string.components(separatedBy: ",")
                fullDate = time2.first!
                let startTime12 = time2.last?.trimmingCharacters(in: .whitespaces)
                fullDate.append(", \(TimeConverter.timeConversion24(time12: startTime12!))")
            }
            return Text(fullDate)
        }
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
