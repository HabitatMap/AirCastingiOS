// Created by Lunar on 05/05/2022.
//

import SwiftUI

struct ExternalSessionHeader: View {
    var session: ExternalSessionEntity
    
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
        let allStreams = session.measurementStreams
        return SessionTypeIndicator(sessionType: .fixed, streamSensorNames: allStreams.compactMap(\.sensorPackageName))
    }

    func adaptTimeAndDate() -> Text {
        let formatter = DateFormatters.SessionCartView.utcDateIntervalFormatter
        
        guard let start = session.startTime else { return Text("") }
        let end = session.endTime ?? DateBuilder.getFakeUTCDate()
        
        let string = formatter.string(from: start, to: end)
        return Text(string)
    }
}

//#if DEBUG
//struct ExternalSessionHeader_Previews: PreviewProvider {
//    static var previews: some View {
//        ExternalSessionHeader()
//    }
//}
//#endif
