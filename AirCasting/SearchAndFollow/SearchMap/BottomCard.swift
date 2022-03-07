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
        }
        .font(Fonts.regularHeading4)
        .foregroundColor(.aircastingGray)
        .padding()
        .background(
            Group {
                Color.white
                    .shadow(color: .sessionCardShadow, radius: 9, x: 0, y: 1)
            }
        )
    }
}
