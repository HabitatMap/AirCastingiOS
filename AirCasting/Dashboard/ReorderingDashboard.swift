// Created by Lunar on 28/01/2022.
//

import SwiftUI

struct ReorderingDashboard: View {
    
    @ObservedObject var viewModel: ReorderingDashboardViewModel
    var thresholds: [SensorThreshold]
    let measurementStreamStorage: MeasurementStreamStorage
    let urlProvider: BaseURLProvider
    
    let columns = [GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(viewModel.sessions) { session in
                    ReoredringSessionCard(session: session, thresholds: thresholds, measurementStreamStorage: measurementStreamStorage, urlProvider: urlProvider)
                        .onDrag({
                            viewModel.currentSession = session
                            return NSItemProvider(contentsOf: URL(string: session.urlLocation ?? "")!)!
                        })
                        .onDrop(of: [.url], delegate: DropViewDelegate(session: session, sessionsData: viewModel))
                }
            }
            .padding()
        }
    }
}

struct ReorderingDashboard_Previews: PreviewProvider {
    static var previews: some View {
        ReorderingDashboard(viewModel: ReorderingDashboardViewModel(sessions: [.mock, .mock]), thresholds: [.mock, .mock], measurementStreamStorage: PreviewMeasurementStreamStorage(), urlProvider: DummyURLProvider())
    }
}
