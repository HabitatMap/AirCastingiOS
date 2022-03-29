// Created by Lunar on 07/03/2022.
//

import Foundation
import SwiftUI

struct BottomCardModel {
    let id: Int
    let title: String
    let startTime: String
    let endTime: String
    let latitude: Double
    let longitude: Double
}

struct BottomCardView: View {
    @State var isModalScreenPresented = false
    @Binding var cardPointer: Int
    let dataModel: BottomCardModel
    
    var body: some View {
        sessionCard
    }
    
    var sessionCard: some View {
        Button {
            cardPointer = dataModel.id
            isModalScreenPresented.toggle()
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(dataModel.title)
                    .foregroundColor(.darkBlue)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.01)
                Spacer(minLength: 0.01)
                dataAndTime
                    .font(Fonts.regularHeading4)
                    .foregroundColor(.aircastingGray)
                    .minimumScaleFactor(0.1)
                    .scaledToFit()
            }
        }
        .sheet(isPresented: $isModalScreenPresented, content: {
            CompleteScreen(session: .init(uuid: .init(rawValue: "\(dataModel.id)") ?? .init(),
                                          name: dataModel.title,
                                          startTime: startTimeAsDate(),
                                          endTime: endTimeAsDate(),
                                          longitude: dataModel.longitude,
                                          latitude: dataModel.latitude))
        })
        .frame(maxWidth: UIScreen.main.bounds.width / 2, alignment: .leading)
        .padding()
        .background(
            Group {
                Color.white
                    .shadow(color: .sessionCardShadow, radius: 9, x: 0, y: 1)
            }
        )
    }
}

private extension BottomCardView {
    var dataAndTime: some View {
        adaptTimeAndDate()
    }
    
    func adaptTimeAndDate() -> Text {
        let formatter = DateFormatters.SessionCartView.utcDateIntervalFormatter

        let start = startTimeAsDate()
        let end = endTimeAsDate()

        let string = formatter.string(from: start, to: end)
        return Text(string)
    }
    
    func startTimeAsDate() -> Date {
        let formatter = DateFormatters.CreateSessionAPIService.encoderDateFormatter
        let date = formatter.date(from: dataModel.startTime)
        guard let d = date else { return Date() }
        return d
    }
    
    func endTimeAsDate() -> Date {
        let formatter = DateFormatters.CreateSessionAPIService.encoderDateFormatter
        let date = formatter.date(from: dataModel.endTime)
        guard let d = date else { return Date() }
        return d
    }
}
