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
    let sessionStopperFactory: SessionStoppableFactory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
                HStack {
                    dateAndTime
                        .foregroundColor(Color.aircastingTimeGray)
                    Spacer()
                    session.isActive ? actionsMenuMobile : nil
                }
            nameLabelAndExpandButton
        }.onChange(of: isCollapsed, perform: { value in
            isCollapsed ? (chevronIndicator = "chevron.down") :  (chevronIndicator = "chevron.up")
        })
        .font(Fonts.regularHeading4)
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
                    .font(Fonts.regularHeading1)
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
                    .font(Fonts.regularHeading4)
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
        .sheet(isPresented: Binding.constant(false)) { EditViewModal(showModalEdit: Binding.constant(false)) }
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
                networkChecker.connectionAvailable ? false : false
            }
        } label: {
            Label(Strings.SessionHeaderView.editButton, systemImage: "pencil")
        }
    }
    
    var actionsMenuFixedShareButton: some View {
        Button {
            // action here
        } label: {
            Label(Strings.SessionHeaderView.shareButton, systemImage: "square.and.arrow.up")
        }
    }
    
    var actionsMenuFixedDeleteButton: some View {
        Button {
            // action here
        } label: {
            Label(Strings.SessionHeaderView.deleteButton, systemImage: "xmark.circle")
        }
    }
   
    func adaptTimeAndDate() -> Text {
        let formatter = DateFormatters.SessionCartView.utcDateIntervalFormatter
        
        guard let start = session.startTime else { return Text("") }
        let end = session.endTime ?? Date().currentUTCTimeZoneDate
        
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
