// Created by Lunar on 12/01/2022.
//

import SwiftUI
import AirCastingStyling

struct ShareLocationlessSessionView: View {
    @ObservedObject var viewModel: ShareLocationlessSessionViewModel
    
    var body: some View {
        LoadingView(isShowing: $viewModel.loaderVisible, activityIndicatorText: Strings.SessionShare.loadingFile) {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 40) {
                    title
                    description
                }
                Spacer()
                VStack(alignment: .leading, spacing: 5) {
                    shareFileButton
                    cancelButton
                }
                Spacer()
            }
            .padding()
            .alert(item: $viewModel.alert, content: { $0.makeAlert() })
            .sheet(isPresented: $viewModel.showShareSheet, content: {
                ActivityViewController(itemsToShare: [viewModel.file as Any]) { activityType, completed, returnedItems, error in
                    viewModel.sharingFinished()
                }
            })
            .padding()
        }
    }
    
    private var title: some View {
        Text(Strings.SessionShare.title)
            .font(Fonts.boldTitle1)
            .foregroundColor(.accentColor)
    }
    
    private var description: some View {
        Text(Strings.SessionShare.locationlessDescription)
    }
    
    private var shareFileButton: some View {
        Button(Strings.SessionShare.shareFileButton) {
            viewModel.shareFileTapped()
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    private var cancelButton: some View {
        Button(Strings.Commons.cancel) {
            viewModel.cancelTapped()
        }.buttonStyle(BlueTextButtonStyle())
    }
}

#if DEBUG
struct ShareLocationlessSession_Previews: PreviewProvider {
    static var previews: some View {
        ShareLocationlessSessionView(viewModel: ShareLocationlessSessionViewModel(session: SessionEntity.mock, fileGenerationController: DummyGenerateSessionFileController(), exitRoute: { }))
    }
}
#endif
