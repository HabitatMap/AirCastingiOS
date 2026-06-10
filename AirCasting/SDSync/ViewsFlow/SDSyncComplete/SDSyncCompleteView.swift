// Created by Lunar on 01/12/2021.
//

import AirCastingStyling
import SwiftUI

struct SDSyncCompleteView<VM: SDSyncCompleteViewModel>: View {
    @StateObject var viewModel: VM
    @Binding var creatingSessionFlowContinues: Bool
    @EnvironmentObject private var tabSelection: TabBarSelector
    @EnvironmentObject private var standaloneSessionToSyncAndFinish: StandaloneSessionToSyncAndFinish
    var isSDClearProcess: Bool

    var body: some View {
        ProgressFlowAB(progress: 0.994,
                       airbeamImageAsset: "4-connected",
                       title: isSDClearProcess ? Strings.SDSyncCompleteView.SDClearTitle : Strings.SDSyncCompleteView.title,
                       message: isSDClearProcess ? Strings.SDSyncCompleteView.SDClearMessage : Strings.SDSyncCompleteView.message) {
            // The "Unplug your AirBeam" terminal screen has been removed for
            // both V1 and V2 — the wizard ends here on continue. (Earlier
            // attempt to insert it pre-sync regressed other flows; keeping
            // it hidden entirely is the user-requested resolution.)
            creatingSessionFlowContinues = false
            tabSelection.update(to: .dashboard)
        }
    }
}
