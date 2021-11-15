// Created by Lunar on 10/11/2021.
//

import SwiftUI
import AirCastingStyling

struct StandaloneSessionCardView: View {
    let session: SessionEntity
    let sessionStopperFactory: SessionStoppableFactory
    @State private var showingFinishAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
            content
        }
        .font(Fonts.regularHeading4)
        .foregroundColor(.aircastingGray)
        .padding()
        .background(Color.white
                        .shadow(color: Color(red: 205/255, green: 209/255, blue: 214/255, opacity: 0.36), radius: 9, x: 0, y: 1))
        .overlay(Rectangle().frame(width: nil, height: 4, alignment: .top).foregroundColor(Color.red), alignment: .top)
    }
    
    var header: some View {
        SessionHeaderView(
            action: {},
            isExpandButtonNeeded: false,
            isCollapsed: .constant(false),
            session: session,
            sessionStopperFactory: sessionStopperFactory
        )
    }
    
    var content: some View {
        VStack(spacing: 15) {
            Text(Strings.StandaloneSessionCardView.heading)
                .font(Fonts.boldHeading3)
                .foregroundColor(.darkBlue)
            Text(Strings.StandaloneSessionCardView.description)
            Button(Strings.StandaloneSessionCardView.buttonLabel) {
                showingFinishAlert = true
            }
            .buttonStyle(BlueButtonStyle())
            .padding()
            .alert(isPresented: $showingFinishAlert) {
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
        .padding()
    }
}

#if DEBUG
struct StandaloneSessionCard_Previews: PreviewProvider {
    static var previews: some View {
        StandaloneSessionCardView(session: SessionEntity.mock, sessionStopperFactory: SessionStoppableFactoryDummy())
    }
}
#endif
