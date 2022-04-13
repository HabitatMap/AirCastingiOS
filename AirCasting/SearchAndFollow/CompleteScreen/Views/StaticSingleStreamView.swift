// Created by Lunar on 28/02/2022.
//

import SwiftUI

struct StaticSingleStreamView: View {
    let streamName: String
    let value: Double
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 3) {
            Button(action: {
                action()
            }, label: {
                VStack(spacing: 1) {
                    Text(streamName)
                        .font(Fonts.systemFont1)
                        .scaledToFill()
                        HStack(spacing: 3) {
                            dot
                            Text("\(Int(value))")
                                .font(Fonts.regularHeading3)
                                .scaledToFill()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(isSelected ? color : .clear)
                        )
                    }
            })
        }
    }
    
    var dot: some View {
        color
            .clipShape(Circle())
            .frame(width: 5, height: 5)
    }
}

struct StaticSingleStreamView_Previews: PreviewProvider {
    static var previews: some View {
        StaticSingleStreamView(streamName: "AirBeam3-PM1", value: 20, color: Color.aircastingGray, isSelected: true) { }
    }
}
