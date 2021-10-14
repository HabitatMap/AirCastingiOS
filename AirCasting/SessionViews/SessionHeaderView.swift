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
    var isSensorTypeNeeded: Bool = true
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
        VStack(alignment: .leading, spacing: 3) {
            ZStack {
                HStack {
                    dateAndTime
                        .foregroundColor(Color.aircastingTimeGray)
                    Spacer()
                }
                HStack {
                    Spacer()
                    session.isActive ? actionsMenuMobile : nil
                }
            }
            .sheet(isPresented: $shareModal, content: {
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
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(session.name ?? "")
                    .font(Font.moderate(size: 18, weight: .regular))
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
            #warning("Fix - Handle session.deviceType (for now it is always nill)")
            if isSensorTypeNeeded {
                sensorType
                .font(Font.moderate(size: 13, weight: .regular))
            }
        }
        .foregroundColor(.darkBlue)
    }
    
    var sensorType: some View {
        var stream = [String]()
        var text = ""
        guard session.allStreams != nil else { return Text("") }
        session.allStreams!.forEach { session in
            if var name = session.sensorPackageName {
                componentsSeparation(name: &name)
                (name == "Builtin") ? (name = "Phone mic") : (name = name)
                !stream.contains(name) ? stream.append(name) : nil
            }
        }
        text = stream.joined(separator: ", ")
        return Text("\(session.type!.description) : \(text)")
    }
    
    func componentsSeparation(name: inout String) {
        // separation is used to nicely handle the case where sensor could be
        // AirBeam2-xxxx or AirBeam2:xxx
        if name.contains(":") {
            name = name.components(separatedBy: ":").first!
        } else {
            name = name.components(separatedBy: "-").first!
        }
    }
    
    var actionsMenuMobile: some View {
        Menu {
            actionsMenuMobileStopButton
        } label: {
            ZStack(alignment: .trailing) {
                EditButtonView()
                Rectangle()
                    .frame(width: 50, height: 35, alignment: .trailing)
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
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateTemplate = "MM/dd/yyyy HH:mm"
        
        if !(session.isMobile && session.isActive && session.deviceType == .MIC) {
            formatter.timeZone =  TimeZone.init(abbreviation: "UTC")
        }
            
            guard var start = session.startTime else { return Text("") }
            var end = session.endTime ?? Date()
        
        if session.isMobile && session.deviceType == .AIRBEAM3 && session.endTime == nil {
            end = end.currentUTCTimeZoneDate
        }
     
        if session.isFixed && session.measurementStreams == [] {
            start = start.currentUTCTimeZoneDate
            end = end.currentUTCTimeZoneDate
        }
        
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
