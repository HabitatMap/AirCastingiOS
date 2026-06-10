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
    /// Phase 6 V1 reorder (Android commit `dcef0b695`): the "Unplug AirBeam"
    /// screen has moved from pre-sync to post-sync. After this success screen,
    /// V1 users get the Unplug prompt; V2 / SD-clear flows skip it.
    @State private var showUnplugAfterSync: Bool = false

    var body: some View {
        ProgressFlowAB(progress: 0.994,
                       airbeamImageAsset: "4-connected",
                       title: isSDClearProcess ? Strings.SDSyncCompleteView.SDClearTitle : Strings.SDSyncCompleteView.title,
                       message: isSDClearProcess ? Strings.SDSyncCompleteView.SDClearMessage : Strings.SDSyncCompleteView.message) {
            if !isSDClearProcess && !standaloneSessionToSyncAndFinish.isV2 {
                showUnplugAfterSync = true
            } else {
                creatingSessionFlowContinues = false
                tabSelection.update(to: .dashboard)
            }
        }
        .background(
            NavigationLink(
                destination: UnplugABFinalView(creatingSessionFlowContinues: $creatingSessionFlowContinues),
                isActive: $showUnplugAfterSync,
                label: { EmptyView() }
            )
        )
    }
}

/// Terminal "Unplug your AirBeam" screen shown AFTER a successful SD-card sync
/// on V1. Mirrors `UnplugABView` but dismisses the wizard on continue instead
/// of pushing `SDRestartABView`.
private struct UnplugABFinalView: View {
    @Binding var creatingSessionFlowContinues: Bool
    @EnvironmentObject private var tabSelection: TabBarSelector

    var body: some View {
        ProgressFlowAB(progress: 0.998,
                       airbeamImageAsset: "airbeam-unplugged",
                       title: Strings.UnplugAirbeamView.title,
                       message: Strings.UnplugAirbeamView.message) {
            creatingSessionFlowContinues = false
            tabSelection.update(to: .dashboard)
        }
    }
}
