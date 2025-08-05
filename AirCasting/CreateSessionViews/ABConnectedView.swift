//
//  AirbeamConnectedView.swift
//  AirCasting
//
//  Created by Lunar on 17/02/2021.
//

import AirCastingStyling
import SwiftUI

struct ABConnectedView: View {
    @Binding var creatingSessionFlowContinues: Bool
    
    var body: some View {
        ProgressFlowAB(progress: 0.625, airbeamImageAsset: "4-connected", title: Strings.ABConnectedView.title, message: Strings.ABConnectedView.message, continueButtonOnClickDestination: CreateSessionDetailsView(creatingSessionFlowContinues: $creatingSessionFlowContinues))
    }
}

#Preview {
    ABConnectedView(creatingSessionFlowContinues: .constant(true))
}
