// Created by Lunar on 28/02/2022.
//

import Foundation
import Charts

class SearchAndFollowChartViewModel: ObservableObject {
    @Published var entries: [ChartDataEntry] = []
    
    init(stream: SearchSession.SearchSessionStream?) {
        guard let stream = stream else { return }
        generateEntries(for: stream)
    }
    
    func setStream(to stream: SearchSession.SearchSessionStream) {
        generateEntries(for: stream)
    }
    
    private func generateEntries(for stream: SearchSession.SearchSessionStream) {
        entries = [
            .init(x: 0, y: 1),
            .init(x: 1, y: 3),
            .init(x: 2, y: 2)
        ]
    }
}
