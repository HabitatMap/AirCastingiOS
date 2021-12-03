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
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @ObservedObject var session: SessionEntity
    @State private var showingAlert = false
    @State private var showingFinishAlert = false
    let sessionStopperFactory: SessionStoppableFactory
    @StateObject private var featureFlagsViewModel = FeatureFlagsViewModel.shared
    @State var showDeleteModal = false
    let measurementStreamStorage: MeasurementStreamStorage
    @EnvironmentObject var authorization: UserAuthenticationSession

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
                HStack {
                    dateAndTime
                        .foregroundColor(Color.aircastingTimeGray)
                    Spacer()
                    actionsMenuMobile
                }
            nameLabelAndExpandButton
        }.onChange(of: isCollapsed, perform: { value in
            isCollapsed ? (chevronIndicator = "chevron.down") :  (chevronIndicator = "chevron.up")
        })
        .sheet(isPresented: Binding.constant(false), content: {
            ShareView(showModal: Binding.constant(false))
        })
        .sheet(isPresented: $showDeleteModal) {
            DeleteView(viewModel: DefaultDeleteSessionViewModel(session: session, measurementStreamStorage: measurementStreamStorage, streamRemover: StreamRemoverDefault(authorization: authorization)), deleteModal: $showDeleteModal)
        }
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
            session.isActive ? actionsMenuStopButton : nil
            session.deletable ? actionsMenuDeleteButton : nil
            if session.deviceType == .AIRBEAM3 && featureFlagsViewModel.enabledFeatures.contains(.standaloneMode) {
                actionsMenuMobileEnterStandaloneMode
            }
        } label: {
            ZStack(alignment: .trailing) {
                EditButtonView()
                Rectangle()
                    .frame(width: 50, height: 35, alignment: .trailing)
                    .opacity(0.0001)
            }
        }
        .alert(isPresented: $showingFinishAlert) {
            SessionViews.finishSessionAlert(sessionStopper: sessionStopperFactory.getSessionStopper(for: session), sessionName: session.name)
        }
    }

    var actionsMenuStopButton: some View {
        Button {
            showingFinishAlert = true
        } label: {
            Label(Strings.SessionHeaderView.stopRecordingButton, systemImage: "stop.circle")
        }
    }

    var actionsMenuMobileEnterStandaloneMode: some View {
        Button {
            bluetoothManager.enterStandaloneMode(sessionUUID: session.uuid)
        } label: {
            Label(Strings.SessionHeaderView.enterStandaloneModeButton, systemImage: "xmark.circle")
        }
    }

    var actionsMenuFixed: some View {
        Menu {
            actionsMenuRepeatButton
            actionsMenuEditButton
            actionsMenuShareButton
            actionsMenuDeleteButton
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

    var actionsMenuRepeatButton: some View {
        Button {
            // action here
        } label: {
            Label("resume", systemImage: "repeat")
        }
    }

    var actionsMenuEditButton: some View {
        Button {
            DispatchQueue.main.async {
                print(" \(networkChecker.connectionAvailable) NETWORK")
                networkChecker.connectionAvailable ? false : false
            }
        } label: {
            Label(Strings.SessionHeaderView.editButton, systemImage: "pencil")
        }
    }

    var actionsMenuShareButton: some View {
        Button {
            // action here
        } label: {
            Label(Strings.SessionHeaderView.shareButton, systemImage: "square.and.arrow.up")
        }
    }

    var actionsMenuDeleteButton: some View {
        Button {
            showDeleteModal = true
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
                          sessionStopperFactory: SessionStoppableFactoryDummy(), measurementStreamStorage: PreviewMeasurementStreamStorage())
                .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
}
#endif
