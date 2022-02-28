// Created by Lunar on 22/02/2022.
//

import SwiftUI

struct SearchCompleteScreenHeader: View {
    var session: SearchSession
    
    var body: some View {
        sessionHeader
    }
}

private extension SearchCompleteScreenHeader {
    var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                dateAndTime
                    .foregroundColor(Color.aircastingTimeGray)
                Spacer()
            }
            .padding(.vertical)
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
            }
            sensorType
                .font(Fonts.regularHeading4)
        }
        .foregroundColor(.darkBlue)
    }
    
    var sensorType: some View {
        let allStreams = session.streams
        return SessionTypeIndicator(sessionType: session.type, streamSensorNames: allStreams.compactMap(\.sensorPackageName))
    }

    func adaptTimeAndDate() -> Text {
        let formatter = DateFormatters.SessionCartView.utcDateIntervalFormatter
        
        let start = session.startTime
        let end = session.endTime
        
        let string = formatter.string(from: start, to: end)
        return Text(string)
    }
}

#if DEBUG
struct SearchCompleteScreenHeader_Previews: PreviewProvider {
    static var previews: some View {
        SearchCompleteScreenHeader(session: SearchSession.mock)
    }
}
#endif
