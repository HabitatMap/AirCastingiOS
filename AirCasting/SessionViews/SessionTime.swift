// Created by Lunar on 02/12/2022.
//

import Foundation
import SwiftUI

struct SessionTime: View {
    @ObservedObject var session: SessionEntity
    
    private var sessionStreams: [MeasurementStreamEntity] {
        return session.sortedStreams
    }
    
    var body: some View {
        if session.isActive, let stream = sessionStreams.first {
            DynamicSessionTime(session: session, stream: stream)
        } else {
            staticTimeAndDate()
        }
    }
    
    func staticTimeAndDate() -> Text {
        let formatter: DateIntervalFormatter = DateFormatters.SessionCardView.shared.utcDateIntervalFormatter
        guard let start = session.startTime else { return Text("") }
        let end = session.endTime ?? DateBuilder.getFakeUTCDate()
        
        let string = formatter.string(from: start, to: end)
        return Text(string)
    }
}

struct DynamicSessionTime: View {
    @ObservedObject var session: SessionEntity
    @ObservedObject var stream: MeasurementStreamEntity
    
    var body: some View {
        Text(formatedTimeAndDate())
    }
    
    func formatedTimeAndDate() -> String {
        let formatter: DateIntervalFormatter = DateFormatters.SessionCardView.shared.utcDateIntervalFormatter
        guard let start = session.startTime else { return "" }
        let end = session.endTime ?? stream.lastMeasurementTime ?? DateBuilder.getFakeUTCDate()
        
        let string = formatter.string(from: start, to: end)
        return string
    }
}
