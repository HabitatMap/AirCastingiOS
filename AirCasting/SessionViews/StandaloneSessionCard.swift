// Created by Lunar on 10/11/2021.
//

import SwiftUI
import AirCastingStyling

struct StandaloneSessionCard: View {
    var session: SessionEntity
    var sessionStopperFactory: SessionStoppableFactory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
            VStack(spacing: 15) {
                Text("Your AirBeam3 is now in stand-alone mode")
                    .font(Fonts.boldHeading3)
                    .foregroundColor(.darkBlue)
                Text("AirBeam3 is now recording using its SD card. The measurements will be displayed here after syncing.")
                Button("Finish recording & don't sync") {
                    do {
                        try sessionStopperFactory.getSessionStopper(for: session).stopSession()
                    } catch {
                        Log.info("error when stpoing session - \(error)")
                    }
                }
                .buttonStyle(BlueButtonStyle())
                .padding()
            }
            .padding()
        }
        .font(Fonts.regularHeading4)
        .foregroundColor(.aircastingGray)
        .padding()
        .background(Color.white
                        .shadow(color: Color(red: 205/255, green: 209/255, blue: 214/255, opacity: 0.36), radius: 9, x: 0, y: 1))
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
}

struct StandaloneSessionCard_Previews: PreviewProvider {
    static var previews: some View {
        StandaloneSessionCard(session: SessionEntity.mock, sessionStopperFactory: SessionStoppableFactoryDummy())
    }
}