// Created by Lunar on 28/01/2022.
//

import SwiftUI

struct ReorderingSessionHeader: View {
    var session: SessionEntity
    
    var body: some View {
        sessionHeader
    }
}

private extension ReorderingSessionHeader {
    var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                dateAndTime
                    .foregroundColor(Color.aircastingTimeGray)
                Spacer()
                Image("draggable-icon")
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
                Text(session.name ?? "")
                    .font(Fonts.regularHeading1)
                Spacer()
            }
            sensorType
                .font(Fonts.regularHeading4)
        }
        .foregroundColor(.darkBlue)
    }
    
    var sensorType: some View {
        let allStreams = session.allStreams ?? []
        return SessionTypeIndicator(sessionType: session.type, streamSensorNames: allStreams.compactMap(\.sensorPackageName))
    }

    func adaptTimeAndDate() -> Text {
        let formatter = DateFormatters.SessionCartView.utcDateIntervalFormatter
        
        guard let start = session.startTime else { return Text("") }
        let end = session.endTime ?? DateBuilder.getFakeUTCDate()
        
        let string = formatter.string(from: start, to: end)
        return Text(string)
    }
}

struct ReorderingSessionHeader_Previews: PreviewProvider {
    static var previews: some View {
        ReorderingSessionHeader(session: SessionEntity.mock)
    }
}