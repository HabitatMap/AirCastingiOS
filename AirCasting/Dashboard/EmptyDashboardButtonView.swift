// Created by Lunar on 25/08/2021.
//

import SwiftUI
import AirCastingStyling

struct EmptyDashboardButtonView: View {
    @EnvironmentObject private var tabSelection: TabBarSelection

    var body: some View {
        Button(action: {
            tabSelection.selection = .createSession
        }, label: {
            Text(Strings.EmptyDashboardMobile.newSession)
                .bold()
        })
        .frame(maxWidth: 250)
        .buttonStyle(BlueButtonStyle())    }
}

struct DashboardButtonView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyDashboardButtonView()
    }
}
