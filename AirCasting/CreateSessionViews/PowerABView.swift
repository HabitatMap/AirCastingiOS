//
//  PowerABView.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import AirCastingStyling
import SwiftUI
import Resolver

struct PowerABView: View {
    @Binding var creatingSessionFlowContinues: Bool

    var body: some View {
        ProgressFlowAB(progress: 0.25, airbeamImageAsset: "2-power", title: Strings.PowerABView.title, message: "", continueButtonOnClickDestination: SelectPeripheralView(SDClearingRouteProcess: false, creatingSessionFlowContinues: $creatingSessionFlowContinues))
    }
}
