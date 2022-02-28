// Created by Lunar on 22/02/2022.
//
// Created by Lunar on 28/01/2022.
//

import SwiftUI
import AirCastingStyling

struct CompleteScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: CompleteScreenViewModel
    @State var selectedStream: Int?
    @State var isMapSelected: Bool = true
    
    init(session: SearchSession) {
        _viewModel = .init(wrappedValue: CompleteScreenViewModel(session: session))
        _selectedStream = .init(wrappedValue: session.streams.first?.id)
    }
    
    var body: some View {
        sessionCard
            .overlay(
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.aircastingDarkGray)
                        .imageScale(.large)
                }).padding(),
                alignment: .topTrailing
            )
    }
    
    var sessionCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
            measurements
            if isMapSelected {
                SearchCompleteScreenMapView(longitude: viewModel.session.longitude, latitude: viewModel.session.latitude)
                    .frame(height: 300)
            } else {
                // ChartView
            }
            buttons
            confirmationButton
            Spacer()
        }
        .font(Fonts.regularHeading4)
        .foregroundColor(.aircastingGray)
        .padding()
    }
}

private extension CompleteScreen {
    var header: some View {
        SearchCompleteScreenHeader(session: viewModel.session)
            .padding(.vertical)
    }
    
    var measurements: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Strings.SessionCart.lastMinuteMeasurement)
                .font(Fonts.moderateTitle1)
                .padding(.bottom, 3)
            if let streams = viewModel.session.streams {
                HStack {
                    streams.count != 1 ? Spacer() : nil
                    ForEach(streams) { stream in
                        singleMeasurement(stream: stream, value: stream.measurements.last?.value ?? 0, selectedStreamId: $selectedStream)
                        Spacer()
                    }
                }
            }
        }
        .padding(.bottom)
    }
    
    var buttons: some View {
        HStack {
            Spacer()
            if isMapSelected {
                Button {
                    isMapSelected.toggle()
                } label: {
                    Text(Strings.SessionCartView.map)
                        .font(Fonts.semiboldHeading2)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(FollowButtonStyle())
                Button {
                    isMapSelected.toggle()
                } label: {
                    Text("Chart")
                        .font(Fonts.semiboldHeading2)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(GrayButtonStyle())
            } else {
                Button {
                    isMapSelected.toggle()
                } label: {
                    Text(Strings.SessionCartView.map)
                        .font(Fonts.semiboldHeading2)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(GrayButtonStyle())
                Button {
                    isMapSelected.toggle()
                } label: {
                    Text("chart")
                        .font(Fonts.semiboldHeading2)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(FollowButtonStyle())
            }
        }
        .padding(.vertical)
    }
    
    var confirmationButton: some View {
        Button {
            //
        } label: {
            Text("Follow Session")
                .font(Fonts.semiboldHeading1)
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    private func singleMeasurement(stream: SearchSession.SearchSessionStream, value: Double, selectedStreamId: Binding<Int?>) -> some View {
        StaticSingleMeasurement(selectedStreamId: selectedStreamId, streamId: stream.id, streamName: stream.sensorName, value: stream.measurements.last?.value ?? 0)
    }
}

#if DEBUG
struct CompleteScreen_Previews: PreviewProvider {
    static var previews: some View {
        CompleteScreen(session: .mock)
    }
}
#endif
