// Created by Lunar on 22/02/2022.
//

import SwiftUI

struct StaticSessionHeader: View {
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
                    .font(Fonts.muliHeading4)
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
                Text(viewModel.sessionName)
                    .font(Fonts.regularHeading1)
                Spacer()
            }
            sensorType
                .font(Fonts.regularHeading4)
        }
        .foregroundColor(.darkBlue)
    }
    
    var sensorType: some View {
        Text(viewModel.sensorType)
    }

    func adaptTimeAndDate() -> Text {
        let formatter = DateFormatters.SessionCartView.utcDateIntervalFormatter

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
