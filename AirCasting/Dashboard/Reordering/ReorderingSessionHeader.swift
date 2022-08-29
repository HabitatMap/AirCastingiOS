// Created by Lunar on 28/01/2022.
//

import SwiftUI
import Resolver

struct ReorderingSessionHeader: View {
    @Environment(\.colorScheme) var colorScheme
    var session: Sessionable
    
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
                    .renderingMode(.template)
                    .foregroundColor(colorScheme == .light ? .black : .aircastingGray)
            }
            nameLabel
        }
        .font(Fonts.moderateRegularHeading4)
        .foregroundColor(.aircastingGray)
    }

    var dateAndTime: some View {
        adaptTimeAndDate()
    }
    
    var nameLabel: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(session.name ?? "")
                    .font(Fonts.moderateMediumHeading1)
                Spacer()
            }
            sensorType
                .font(Fonts.moderateRegularHeading4)
        }
        .foregroundColor(.darkBlue)
    }
    
    var sensorType: some View {
        let allStreams = session.allStreams
        return SessionTypeIndicator(sessionType: .fixed, streamSensorNames: allStreams.compactMap(\.sensorPackageName))
    }

    func adaptTimeAndDate() -> Text {
        let formatter: DateIntervalFormatter = DateFormatters.SessionCardView.shared.utcDateIntervalFormatter
        guard let start = session.startTime else { return Text("") }
        let end = session.endTime ?? DateBuilder.getFakeUTCDate()
        
        let string = formatter.string(from: start, to: end)
        return Text(string)
    }
}

#if DEBUG
struct ReorderingSessionHeader_Previews: PreviewProvider {
    static var previews: some View {
        ReorderingSessionHeader(session: SessionEntity.mock)
    }
}
#endif
