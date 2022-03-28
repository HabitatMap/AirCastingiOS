// Created by Lunar on 07/03/2022.
//

import Foundation
import SwiftUI

struct BottomCardModel {
    let id: Int
    let title: String
    let startTime: String
}

struct BottomCardView: View {
    @Binding var cardPointer: Int
    let dataModel: BottomCardModel
    
    var body: some View {
        sessionCard
    }
    
    var sessionCard: some View {
        Button {
            cardPointer = dataModel.id
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(dataModel.title)
                    .foregroundColor(.darkBlue)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Spacer()
                dataAndTime
                    .font(Fonts.regularHeading4)
                    .foregroundColor(.aircastingGray)
            }
        }
        .frame(width: 150, height: 70, alignment: .center)
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
        adaptTime()
    }
    
    func adaptTime() -> Text {
        let formatter = DateFormatters.CreateSessionAPIService.encoderDateFormatter
        let date = formatter.date(from: dataModel.startTime)
        guard let d = date else { return Text("") }
        let formatter2 = DateFormatters.SearchAndFollow.format
        let string = formatter2.string(from: d)
        return Text(string)
    }
}
