// Created by Lunar on 22/02/2022.
//

import SwiftUI
import Resolver

struct StaticSessionHeader: View {
    @InjectedObject private var userSettings: UserSettings
    @StateObject var viewModel: StaticSessionHeaderViewModel
    
    init(name: String, startTime: Date, endTime: Date, sensorType: String) {
        _viewModel = .init(wrappedValue: StaticSessionHeaderViewModel(name: name, startTime: startTime, endTime: endTime, sensorType: sensorType))
    }
    
    var body: some View {
        sessionHeader
    }
}

private extension StaticSessionHeader {
    var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                dateAndTime
                    .font(Fonts.muliRegularHeading5)
                    .foregroundColor(Color.aircastingTimeGray)
                Spacer()
            }
            .padding(.vertical)
            nameLabel
        }
        .font(Fonts.muliRegularHeading5)
        .foregroundColor(.aircastingGray)
    }

    var dateAndTime: some View {
        adaptTimeAndDate()
    }
    
    var nameLabel: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(viewModel.sessionName)
                    .font(Fonts.moderateMediumHeading1)
                Spacer()
            }
            sensorType
                .font(Fonts.muliRegularHeading5)
        }
        .foregroundColor(.darkBlue)
    }
    
    var sensorType: some View {
        Text(viewModel.sensorType)
    }

    func adaptTimeAndDate() -> Text {
        var formatter: DateIntervalFormatter {
            if userSettings.twentyFourHour { return DateFormatters.SessionCardView.utcDateIntervalFormatter }
            return DateFormatters.SessionCardView.utcDateInterval12hFormatter
        }

        let start = viewModel.sessionStartTime
        let end = viewModel.sessionEndTime

        let string = formatter.string(from: start, to: end)
        return Text(string)
    }
}

#if DEBUG
struct StaticSessionHeader_Previews: PreviewProvider {
    static var previews: some View {
        StaticSessionHeader(name: "Test Session", startTime: DateBuilder.getFakeUTCDate(), endTime: DateBuilder.getFakeUTCDate(), sensorType: "AirBeam2")
    }
}
#endif
