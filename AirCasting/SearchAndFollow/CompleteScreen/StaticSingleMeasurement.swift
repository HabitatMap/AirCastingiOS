// Created by Lunar on 28/02/2022.
//

import SwiftUI

struct StaticSingleMeasurement: View {
    @Binding var selectedStreamId: Int?
    var streamId: Int
    var streamName: String
    var value: Double
    
    var body: some View {
        VStack(spacing: 3) {
            Button(action: {
                selectedStreamId = streamId
            }, label: {
                VStack(spacing: 1) {
                    Text(showStreamName(streamName))
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
                                .strokeBorder((selectedStreamId == streamId) ? Color.aircastingGray : .clear)
                        )
                    }
            })
        }
    }
    
    var dot: some View {
        Color.aircastingGray
            .clipShape(Circle())
            .frame(width: 5, height: 5)
    }
    
    func showStreamName(_ streamName: String) -> String {
        streamName
            .replacingOccurrences(of: ":", with: "-")
            .drop { $0 != "-" }
            .replacingOccurrences(of: "-", with: "")
    }
}

struct StaticSingleMeasurement_Previews: PreviewProvider {
    static var previews: some View {
        StaticSingleMeasurement(selectedStreamId: .constant(3), streamId: 3, streamName: "AirBeam3-PM1", value: 20)
    }
}
