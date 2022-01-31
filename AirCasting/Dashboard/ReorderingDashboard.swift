// Created by Lunar on 28/01/2022.
//

import SwiftUI

struct ReorderingDashboard: View {
    
    @ObservedObject var viewModel: ReorderingDashboardViewModel
    @State private var changedView: Bool = false
    var thresholds: [SensorThreshold]
    let measurementStreamStorage: MeasurementStreamStorage
    let urlProvider: BaseURLProvider
    
    let columns = [GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(viewModel.sessions) { session in
                    ReoredringSessionCard(session: session, thresholds: thresholds, measurementStreamStorage: measurementStreamStorage, urlProvider: urlProvider)
                        .overlay(viewModel.currentSession == session && changedView ? Color.white.opacity(0.8) : Color.clear)
                        .onDrag({
                            viewModel.currentSession = session
                            changedView = false
                            return NSItemProvider(object: String(describing: session.uuid) as NSString)
                        })
                        .onDrop(of: [.text], delegate: DropViewDelegate(session: session, currentSession: $viewModel.currentSession, sessions: $viewModel.sessions, changedView: $changedView))
                }
            }
            .padding()
        }
        .background(Color.clear.edgesIgnoringSafeArea(.all)) // this is added to avoid session card staying 0.8 opaque when user drops card on the edges
        .onDrop(of: [.text], delegate: DropOutsideOfGridDelegate(currentSession: $viewModel.currentSession))
    }
}

struct ReorderingDashboard_Previews: PreviewProvider {
    static var previews: some View {
        ReorderingDashboard(viewModel: ReorderingDashboardViewModel(sessions: [.mock, .mock, .mock]), thresholds: [.mock, .mock], measurementStreamStorage: PreviewMeasurementStreamStorage(), urlProvider: DummyURLProvider())
    }
}
