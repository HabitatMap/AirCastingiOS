// Created by Lunar on 23/08/2021.
//
import AirCastingStyling
import SwiftUI

struct EmptyFixedDashboardView: View {
    
    var body: some View {
        emptyState
    }

    private var emptyState: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("dashboard-background-thing")
            
            VStack() {
                Spacer()
                VStack(spacing: 20) {
                    emptyFixedDashboardText
                    EmptyDashboardButtonView(isFixed: true)
                }
                // Additional padding to put the text at similar height
                // as in mobile empty dashboard
                .padding(.bottom, 100)
                Spacer()
            }
        }
        .padding()
        .background(Color(red: 251/255, green: 253/255, blue: 255/255))
    }
}

private extension EmptyFixedDashboardView {
    
    private var emptyFixedDashboardText: some View {
        VStack(spacing: 14) {
            Text(Strings.EmptyDashboardFixed.title)
                .font(Font.moderate(size: 24, weight: .bold))
                .foregroundColor(Color.darkBlue)
                .minimumScaleFactor(0.1)
            
            Text(Strings.EmptyDashboardFixed.description)
                .font(Font.muli(size: 16))
                .foregroundColor(Color.aircastingGray)
                .lineSpacing(9.0)
                .padding(.horizontal, 35)
        }
        .padding(.bottom, 30)
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
    }
}

struct EmptyDashboardViewFixed_Previews: PreviewProvider {
    static var previews: some View {
        EmptyFixedDashboardView()
    }
}
