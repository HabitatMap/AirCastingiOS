// Created by Lunar on 05/05/2022.
//

import SwiftUI

struct ExternalSessionHeader: View {
    @ObservedObject var session: ExternalSessionEntity
    let action: () -> Void
    @State var chevronIndicator = "chevron.down"
    
    var body: some View {
        sessionHeader
    }
}


private extension ExternalSessionHeader {
    var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                dateAndTime
                    .foregroundColor(Color.aircastingTimeGray)
            }
            nameLabel
        }
        .font(Fonts.regularHeading4)
        .foregroundColor(.aircastingGray)
    }

    var dateAndTime: some View {
        adaptTimeAndDate()
    }
    
    var nameLabel: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(session.name)
                    .font(Fonts.regularHeading1)
                Spacer()
                Button(action: {
                    action()
                    chevronIndicator = chevronIndicator == "chevron.down" ? "chevron.up" : "chevron.down"
                }) {
                    Image(systemName: chevronIndicator)
                        .renderingMode(.original)
                }
            }
            sensorType
                .font(Fonts.regularHeading4)
        }
        .foregroundColor(.darkBlue)
    }
    
    var sensorType: some View {
        let allStreams = session.measurementStreams
        return SessionTypeIndicator(sessionType: .fixed, streamSensorNames: allStreams.compactMap(\.sensorPackageName))
    }

    func adaptTimeAndDate() -> Text {
        let formatter = DateFormatters.SessionCartView.utcDateIntervalFormatter
        
        let start = session.startTime
        let end = session.endTime ?? DateBuilder.getFakeUTCDate()
        
        let string = formatter.string(from: start, to: end)
        return Text(string)
    }
}
