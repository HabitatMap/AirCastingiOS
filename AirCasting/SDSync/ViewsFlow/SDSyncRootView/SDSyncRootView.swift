// Created by Lunar on 16/11/2021.
//

import SwiftUI

struct SDSyncRootView<VM: SDSyncRootViewModel>: View {
    @StateObject var viewModel: VM
    @EnvironmentObject private var finishAndSyncButtonTapped: FinishAndSyncButtonTapped
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Binding var creatingSessionFlowContinues: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            ProgressView(value: 0.1)
            Spacer()
            ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom), content: {
                syncImage
                loader
                    .padding()
                    .padding(.vertical)
            })
            Spacer()
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            Spacer()
        }
        .padding()
        .background(navigationLink)
        .onAppear() {
            finishAndSyncButtonTapped.finishAndSyncButtonWasTapped = false
            viewModel.executeBackendSync()
        }
    }
}

private extension SDSyncRootView {
    var syncImage: some View {
        Image("airbeam")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    
    var titleLabel: some View {
        Text(Strings.SDSyncRootView.title)
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.SDSyncRootView.message)
            .font(Fonts.regularHeading1)
            .foregroundColor(.aircastingGray)
    }
    
    var loader: some View {
        ZStack {
            Color.accentColor
                .frame(width: 70, height: 70)
                .clipShape(Circle())
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                .scaleEffect(2)
        }
    }
    
    var navigationLink: some View {
        NavigationLink(
            destination: BackendSyncCompletedView(viewModel: BackendSyncCompletedViewModelDefault(urlProvider: viewModel.urlProvider, bluetoothHandler: DefaultBluetoothHandler(bluetoothManager: bluetoothManager)), creatingSessionFlowContinues: $creatingSessionFlowContinues),
            isActive: $viewModel.backendSyncCompleted,
            label: {
                EmptyView()
            })
    }
}

#if DEBUG
struct SDSyncRootView_Previews: PreviewProvider {
    static var previews: some View {
        SDSyncRootView(viewModel: DummySDSyncRootViewModelDefault(),
                       creatingSessionFlowContinues: .constant(false))
    }
}
#endif
