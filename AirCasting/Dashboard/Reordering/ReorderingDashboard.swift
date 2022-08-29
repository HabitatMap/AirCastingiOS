// Created by Lunar on 28/01/2022.
//

import SwiftUI

struct ReorderingDashboard: View {
    
    @StateObject var viewModel: ReorderingDashboardViewModel
    @State private var editMode = EditMode.active
    @EnvironmentObject var searchAndFollowButton: SearchAndFollowButton
    @State private var changedView: Bool = false
    
    init(sessions: [Sessionable], thresholds: [SensorThreshold]) {
        _viewModel = .init(wrappedValue: ReorderingDashboardViewModel(sessions: sessions, thresholds: thresholds))
    }
    
    private let columns = [GridItem(.flexible())]
    
    var body: some View {
//        ScrollView {
            List {
                ForEach(viewModel.sessions, id: \.uuid) { session in
                    ReoredringSessionCard(session: session, thresholds: viewModel.thresholds)
//                        .overlay(viewModel.currentlyDraggedSession?.uuid == session.uuid && changedView ? Color.white.opacity(0.8) : Color.clear)
//                        .onDrag({
//                            viewModel.currentlyDraggedSession = session
//                            changedView = false
//                            return NSItemProvider(object: String(describing: session.uuid) as NSString)
//                        })
//                        .onDrop(of: [.text], delegate: DropViewDelegate(sessionAtDropDestination: session, currentlyDraggedSession: $viewModel.currentlyDraggedSession, sessions: $viewModel.sessions, changedView: $changedView))
                }
                .onMove(perform: move)
                .onDelete(perform: { _ in Log.debug("Delete") })
            }
            .environment(\.editMode, $editMode)
            .listStyle(.plain)
            .padding()
//        }
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
    
    func move(from source: IndexSet, to destination: Int) {
        viewModel.sessions.move(fromOffsets: source, toOffset: destination)
    }
}

#if DEBUG
struct ReorderingDashboard_Previews: PreviewProvider {
    static var previews: some View {
        ReorderingDashboard(sessions: [SessionEntity.mock(uuid: "mock1"), SessionEntity.mock(uuid: "mock2"), SessionEntity.mock(uuid: "mock3")], thresholds: [.mock, .mock])
            .environmentObject(SearchAndFollowButton())
    }
}
#endif
