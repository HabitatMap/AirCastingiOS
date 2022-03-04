// Created by Lunar on 22/02/2022.
//

import SwiftUI
import AirCastingStyling

struct CompleteScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: CompleteScreenViewModel
    
    init(session: SearchSession) {
        _viewModel = .init(wrappedValue: CompleteScreenViewModel(session: session))
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
            if let selectedStream = viewModel.streamForChart {
                measurements
                if viewModel.isMapSelected {
                    SearchCompleteScreenMapView(longitude: viewModel.sessionLongitude, latitude: viewModel.sessionLatitude)
                } else {
                    SearchAndFollowChartView(stream: selectedStream)
                }
                buttons
            } else {
                Text(Strings.CompleteSearchView.noStreamsDescription)
                    .padding(.vertical)
                SearchCompleteScreenMapView(longitude: viewModel.sessionLongitude, latitude: viewModel.sessionLatitude)
            }
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
        StaticSessionHeader(name: viewModel.sessionName, startTime: viewModel.sessionStartTime, endTime: viewModel.sessionEndTime, sensorType: viewModel.sensorType)
            .padding(.vertical)
    }
    
    var measurements: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Strings.SessionCart.lastMinuteMeasurement)
                .font(Fonts.moderateTitle1)
                .padding(.bottom, 3)
            if let streams = viewModel.sessionStreams {
                HStack {
                    streams.count != 1 ? Spacer() : nil
                    ForEach(streams) { stream in
                        StaticSingleStreamView(selectedStreamId: $viewModel.selectedStream, streamId: stream.id, streamName: stream.sensorName, value: stream.measurements.last?.value ?? 0)
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
            if viewModel.isMapSelected {
                mapButton
                .buttonStyle(FollowButtonStyle())
                chartButton
                .buttonStyle(GrayButtonStyle())
            } else {
                mapButton
                .buttonStyle(GrayButtonStyle())
                chartButton
                .buttonStyle(FollowButtonStyle())
            }
        }
        .padding(.vertical)
    }
    
    var mapButton: some View {
        Button {
            viewModel.mapTapped()
        } label: {
            Text(Strings.CompleteSearchView.map)
                .font(Fonts.semiboldHeading2)
                .padding(.horizontal, 8)
        }
    }
    
    var chartButton: some View {
        Button {
            viewModel.chartTapped()
        } label: {
            Text(Strings.CompleteSearchView.chart)
                .font(Fonts.semiboldHeading2)
                .padding(.horizontal, 8)
        }
    }
    
    var confirmationButton: some View {
        Button {
            //
        } label: {
            Text(Strings.CompleteSearchView.confirmationButtonTitle)
                .font(Fonts.semiboldHeading1)
        }
        .buttonStyle(BlueButtonStyle())
    }
}

#if DEBUG
struct CompleteScreen_Previews: PreviewProvider {
    static var previews: some View {
        CompleteScreen(session: .mock)
    }
}
#endif
