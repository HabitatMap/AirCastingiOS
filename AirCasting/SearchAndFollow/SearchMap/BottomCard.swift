// Created by Lunar on 07/03/2022.
//

import Foundation
import SwiftUI

struct BottomCardView: View {
    
    var body: some View {
        sessionCard
    }
    
    var sessionCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Testowana sesja")
                .font(Fonts.boldHeading2)
                .foregroundColor(.darkBlue)
            dataAndTime
            streams
            
        }
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
        Text("12.02.2019 13:10 - 14:15")
            .font(Fonts.regularHeading4)
            .foregroundColor(.aircastingGray)
    }
    
    var streams: some View {
        Text("PM1 PM2.5 PM10 F RH")
            .font(Fonts.regularHeading4)
            .foregroundColor(.aircastingGray)
    }
}
