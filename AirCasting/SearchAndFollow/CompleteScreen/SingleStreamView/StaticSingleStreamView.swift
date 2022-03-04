// Created by Lunar on 28/02/2022.
//

import SwiftUI

struct StaticSingleStreamView: View {
    @StateObject var viewModel: StaticSingleStreamViewModel
    @Binding var selectedStreamId: Int?
    
    init(selectedStreamId: Binding<Int?>,streamId: Int, streamName: String, value: Double) {
        _selectedStreamId = .init(projectedValue: selectedStreamId)
        _viewModel = .init(wrappedValue: StaticSingleStreamViewModel(streamId: streamId, streamName: streamName, value: value))
    }
    
    var body: some View {
        VStack(spacing: 3) {
            Button(action: {
                selectedStreamId = viewModel.streamId
            }, label: {
                VStack(spacing: 1) {
                    Text(viewModel.streamName)
                        .font(Fonts.systemFont1)
                        .scaledToFill()
                        HStack(spacing: 3) {
                            dot
                            Text("\(Int(viewModel.value))")
                                .font(Fonts.regularHeading3)
                                .scaledToFill()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder((selectedStreamId == viewModel.streamId) ? Color.aircastingGray : .clear)
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
}

struct StaticSingleStreamView_Previews: PreviewProvider {
    static var previews: some View {
        StaticSingleStreamView(selectedStreamId: .constant(3), streamId: 3, streamName: "AirBeam3-PM1", value: 20)
    }
}
