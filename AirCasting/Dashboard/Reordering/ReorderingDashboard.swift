// Created by Lunar on 28/01/2022.
//

import SwiftUI
import CoreData

struct ReorderingDashboard: View {
    
    @StateObject var viewModel: ReorderingDashboardViewModel
    @EnvironmentObject var searchAndFollowButton: SearchAndFollowButton
    @State private var changedView: Bool = false
    
    init(thresholds: [SensorThreshold]) {
        _viewModel = .init(wrappedValue: ReorderingDashboardViewModel(thresholds: thresholds))
    }
    
    private let columns = [GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(viewModel.sessions, id: \.uuid) { session in
                    ReoredringSessionCard(session: session, thresholds: viewModel.thresholds)
                        .overlay(viewModel.currentlyDraggedSession?.uuid == session.uuid && changedView ? Color.aircastingWhite.opacity(0.8) : Color.clear)
                        .onDrag({
                            viewModel.currentlyDraggedSession = session
                            changedView = false
                            return NSItemProvider(object: String(describing: session.uuid) as NSString)
                        })
                        .onDrop(of: [.text], delegate: DropViewDelegate(sessionAtDropDestination: session, currentlyDraggedSession: $viewModel.currentlyDraggedSession, sessions: $viewModel.sessions, changedView: $changedView))
                        .trailingSwipeAction {
                            withAnimation(.easeOut(duration: 0.5)) {
                                viewModel.clear(session: session)
                            }
                        }
                }
            }
            .padding()
        }
        .onAppear(perform: {
            searchAndFollowButton.isHidden = true
        })
        .navigationBarTitle(Strings.ReorderingDashboard.navigationTitle)
        .background(Color.aircastingWhite)
        // this is added to avoid session card staying 0.8 opaque when user drops card on the edges
        .onDrop(of: [.text], delegate: DropOutsideOfGridDelegate(currentlyDraggedSession: $viewModel.currentlyDraggedSession))
        .onDisappear() {
            searchAndFollowButton.isHidden = false
            viewModel.finish()
        }
    }
}

#if DEBUG
struct ReorderingDashboard_Previews: PreviewProvider {
    static var previews: some View {
        ReorderingDashboard(thresholds: [.mock, .mock])
            .environmentObject(SearchAndFollowButton())
    }
}
#endif
