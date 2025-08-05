// Created by Lunar on 01/12/2021.
//

import AirCastingStyling
import SwiftUI

struct SDSyncCompleteView<VM: SDSyncCompleteViewModel>: View {
    @StateObject var viewModel: VM
    @Binding var creatingSessionFlowContinues: Bool
    @EnvironmentObject private var tabSelection: TabBarSelector
    var isSDClearProcess: Bool
    
    var body: some View {
        ProgressFlowAB(progress: 0.994, airbeamImageAsset: "4-connected", title: isSDClearProcess ? Strings.SDSyncCompleteView.SDClearTitle : Strings.SDSyncCompleteView.title, message: isSDClearProcess ? Strings.SDSyncCompleteView.SDClearMessage : Strings.SDSyncCompleteView.message) {
            creatingSessionFlowContinues = false
            tabSelection.update(to: .dashboard)
        }
    }
}
