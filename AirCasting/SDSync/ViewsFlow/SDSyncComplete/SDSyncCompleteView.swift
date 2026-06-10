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
            // V1 used to terminate this wizard with a second "Unplug your
            // AirBeam" prompt; that step has moved to the pre-sync slot
            // (between device selection and SyncingABView) so the wizard
            // ends here for both V1 and V2.
            creatingSessionFlowContinues = false
            tabSelection.update(to: .dashboard)
        }
    }
}
