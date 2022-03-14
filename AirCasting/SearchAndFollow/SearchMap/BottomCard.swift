// Created by Lunar on 07/03/2022.
//

import Foundation
import SwiftUI

struct BottomCardView: View {
    let id: Int
    @Binding var cardPointer: Int
    let title: String
    let startTime: String
    
    var body: some View {
        sessionCard
    }
    
    var sessionCard: some View {
        Button {
            cardPointer = id
            Log.info("Clicked \(cardPointer) and \(id)")
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .foregroundColor(.darkBlue)
                    .lineLimit(2)
                    .scaledToFit()
                    .multilineTextAlignment(.leading)
                dataAndTime
                streams
                
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
        return Text(startTime)
            .font(Fonts.regularHeading4)
            .foregroundColor(.aircastingGray)
    }
    
    var streams: some View {
        Text("PM1 PM2.5 PM10 F RH")
            .font(Fonts.regularHeading4)
            .foregroundColor(.aircastingGray)
    }
}
