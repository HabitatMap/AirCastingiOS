// Created by Lunar on 07/03/2022.
//

import Foundation
import SwiftUI

struct BottomCardView: View {
    @State var isModalScreenPresented = false
    @Binding var cardPointer: Int
    let dataModel: BottomCardModel
    
    var body: some View {
        sessionCard
    }
    
    var sessionCard: some View {
        Button {
            onButtonClick()
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(dataModel.title)
                    .foregroundColor(.darkBlue)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0.01)
                dataAndTime
                    .font(Fonts.regularHeading4)
                    .foregroundColor(.aircastingGray)
                    .minimumScaleFactor(0.1)
                    .scaledToFit()
            }
        }
        .sheet(isPresented: $isModalScreenPresented, content: { initCompleteScreen() })
        .frame(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.height / 9, alignment: .leading)
        .padding([.all], 10)
        .background(
            Group {
                Color.white
                    .shadow(color: .sessionCardShadow, radius: 9, x: 0, y: 1)
            }
        )
    }
}

// MARK: - Private View Components and Methods
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
        let formatter = DateFormatters.SearchAndFollow.timeFormatter
        let date = formatter.date(from: dataModel.startTime)
        guard let d = date else { return Date() }
        return d
    }
    
    func endTimeAsDate() -> Date {
        let formatter = DateFormatters.SearchAndFollow.timeFormatter
        let date = formatter.date(from: dataModel.endTime)
        guard let d = date else { return Date() }
        return d
    }
    
    func onButtonClick() {
        cardPointer = dataModel.id
        isModalScreenPresented.toggle()
    }
    
    func initCompleteScreen() -> CompleteScreen {
        CompleteScreen(session: .init(uuid: .init(rawValue: "\(dataModel.id)") ?? .init(),
                                      name: dataModel.title,
                                      startTime: startTimeAsDate(),
                                      endTime: endTimeAsDate(),
                                      longitude: dataModel.longitude,
                                      latitude: dataModel.latitude))
    }
}
