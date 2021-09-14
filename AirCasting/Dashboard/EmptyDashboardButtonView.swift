// Created by Lunar on 25/08/2021.
//

import SwiftUI
import AirCastingStyling

struct EmptyDashboardButtonView: View {
    @EnvironmentObject private var tabSelection: TabBarSelection
    var isFixed: Bool
    var body: some View {
        Button(action: {
                if isFixed {
                    tabSelection.selection = .createSession
                } else {
                    tabSelection.selection = .createSession
                    tabSelection.mobileProcceding = true
                }
        }, label: {
            if isFixed {
                Text(Strings.EmptyDashboardMobile.buttonFixed)
                    .bold()
            } else {
                Text(Strings.EmptyDashboardMobile.buttonMobile)
                    .bold()
            }
        })
        .frame(maxWidth: 250)
        .buttonStyle(BlueButtonStyle())    }
}
