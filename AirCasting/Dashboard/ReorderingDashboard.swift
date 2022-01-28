// Created by Lunar on 28/01/2022.
//

import SwiftUI

struct ReorderingDashboard: View {
    @State var sessions: [SessionEntity]
    var thresholds: [SensorThreshold]
    let measurementStreamStorage: MeasurementStreamStorage
    let urlProvider: BaseURLProvider
    
    let columns = [GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(sessions) { session in
                    ReoredringSessionCard(session: session, thresholds: thresholds, measurementStreamStorage: measurementStreamStorage, urlProvider: urlProvider)
                }
            }
        }
    }
}

struct ReorderingDashboard_Previews: PreviewProvider {
    static var previews: some View {
        ReorderingDashboard(sessions: [SessionEntity.mock, SessionEntity.mock], thresholds: [.mock, .mock], measurementStreamStorage: PreviewMeasurementStreamStorage(), urlProvider: DummyURLProvider())
    }
}
