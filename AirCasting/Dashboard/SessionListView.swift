// Created by Lunar on 25/09/2021.
//

import SwiftUI

struct SessionListView: View {
    @ObservedObject var coreDataHook: CoreDataHook
    @FetchRequest<SensorThreshold>(sortDescriptors: [.init(key: "sensorName", ascending: true)]) var thresholds
    let measurementStreamStorage: MeasurementStreamStorage
    let sessionStoppableFactory: SessionStoppableFactory
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("dashboard-background-thing")
            let thresholds = Array(self.thresholds)
            ScrollView(.vertical) {
                LazyVStack(spacing: 20) {
                    ForEach(coreDataHook.sessions, id: \.uuid) { session in
                        let followingSetter = MeasurementStreamStorageFollowingSettable(session: session, measurementStreamStorage: measurementStreamStorage)
                        let viewModel = SessionCartViewModel(followingSetter: followingSetter)
                        SessionCartView(session: session,
                                        sessionCartViewModel: viewModel,
                                        thresholds: thresholds,
                                        sessionStoppableFactory: sessionStoppableFactory,
                                        measurementStreamStorage: measurementStreamStorage)
                    }                        }
            }
        }.padding()
            .frame(maxWidth: .infinity)
            .background(Color.aircastingGray.opacity(0.05))
    }
}
