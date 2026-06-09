//  Created by Lunar on 04/02/2021.
//

import SwiftUI
import AirCastingStyling
import Resolver

struct ConnectingABView: View {
    @StateObject var viewModel: AirbeamConnectionViewModel
    @Binding var creatingSessionFlowContinues: Bool
    @State private var showNextScreen: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    init(sessionContext: CreateSessionContext, device: any BluetoothDevice, creatingSessionFlowContinues: Binding<Bool>) {
        _viewModel = .init(wrappedValue: AirbeamConnectionViewModel(sessionContext: sessionContext, device: device))
        self._creatingSessionFlowContinues = .init(projectedValue: creatingSessionFlowContinues)
    }
    
    var body: some View {
        ProgressFlowAB(progress: 0.5, abImage: ABCircleAndLoader(airbeamImage: "airbeam-connecting"), title: Strings.ConnectingABView.title, message: Strings.ConnectingABView.message)
        .background(
            NavigationLink(
                destination: ABConnectedView(creatingSessionFlowContinues: $creatingSessionFlowContinues),
                isActive: $showNextScreen,
                label: {
                    EmptyView()
                }
            )
        )
        .onChange(of: viewModel.isDeviceConnected, perform: { isConnected in
            showNextScreen = isConnected
        })
        .onChange(of: viewModel.shouldDismiss, perform: { shouldDismiss in
            if shouldDismiss { presentationMode.wrappedValue.dismiss() }
        })
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
        .onAppear(perform: {
            /* App is pushing the next view before this view is fully loaded. It resulted with showing next view and going back to this one.
             The async enables app to load this view and then push the next one. */
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                viewModel.connectToAirBeam()
            }
        })
    }
}

#Preview {
    ConnectingABView(sessionContext: CreateSessionContext(), device: PreviewBluetoothDevice(), creatingSessionFlowContinues: .constant(true))
}
