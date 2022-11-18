// Created by Lunar on 22/02/2022.
//

import SwiftUI
import AirCastingStyling
import Resolver

struct CompleteScreen: View {
    @StateObject var viewModel: CompleteScreenViewModel
    @Injected private var locationTracker: LocationTracker
    
    init(session: PartialExternalSession, exitRoute: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: CompleteScreenViewModel(session: session, exitRoute: exitRoute))
    }
    
    var body: some View {
        sessionCard
            .overlay(
                Button(action: {
                    viewModel.xMarkTapped()
                }, label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.aircastingDarkGray)
                        .imageScale(.large)
                }).padding(),
                alignment: .topTrailing
            )
            .alert(item: $viewModel.alert, content: { $0.makeAlert() })
    }
    
    var sessionCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
            if viewModel.sessionStreams.isReady {
                measurements
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(.vertical)
            }
            if viewModel.isMapSelected {
                _MapView(path: [.init(lat: viewModel.sessionLatitude, long: viewModel.sessionLongitude, value: 0.0)],
                         type: .normal,
                         trackingStyle: .latestPathPoint,
                         userIndicatorStyle: .custom(color: .accentColor),
                         userTracker: UserTrackerAdapter(locationTracker))
//                SearchCompleteScreenMapView(longitude: viewModel.sessionLongitude, latitude: viewModel.sessionLatitude)
            } else {
                SearchAndFollowChartView(viewModel: viewModel.chartViewModel)
                chartDescription
            }
            buttons
            if viewModel.isSessionFollowed {
                unfollowButton
            } else {
                followButton
            }
            Spacer()
        }
        .font(Fonts.moderateRegularHeading4)
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
            Text(Strings.CompleteSearchView.lastMeasurement)
                .font(Fonts.muliRegularHeading5)
                .padding(.bottom, 3)
            if let streams = viewModel.sessionStreams.get {
                HStack {
                    streams.count != 1 ? Spacer() : nil
                    ForEach(streams) { stream in
                        let isSelected = stream.id == viewModel.selectedStream
                        StaticSingleStreamView(streamName: stream.sensorName, value: stream.lastMeasurementValue, color: stream.color, isSelected: isSelected) {
                            viewModel.selectedStream(with: stream.id)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(.bottom)
    }
    
    var chartDescription: some View {
        HStack() {
            formatChartTime(time: viewModel.chartStartTime)
            Spacer()
            chartDescriptionText
            Spacer()
            formatChartTime(time: viewModel.chartEndTime)
        }
        .font(Fonts.muliRegularHeading6)
    }

    func formatChartTime(time: Date?) -> some View {
        let formatter = DateFormatters.SessionCardView.shared.pollutionChartDateFormatter

        let date = time ?? DateBuilder.getFakeUTCDate()

        let string = formatter.string(from: date)
        return Text(string)
    }
    
    var chartDescriptionText: some View {
        Text("\(Strings.SessionCartView.avgSessionH) \(viewModel.selectedStreamUnitSymbol ?? "")")
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
                .font(Fonts.muliSemiboldHeading2)
                .padding(.horizontal, 8)
        }
    }
    
    var chartButton: some View {
        Button {
            viewModel.chartTapped()
        } label: {
            Text(Strings.CompleteSearchView.chart)
                .font(Fonts.muliSemiboldHeading2)
                .padding(.horizontal, 8)
        }
    }
    
    var followButton: some View {
        Button {
            viewModel.followButtonPressed()
        } label: {
            Text(viewModel.followButtonText)
                .font(Fonts.muliBoldHeading1)
        }
        .buttonStyle(BlueButtonStyle())
        .disabled(!viewModel.followButtonEnabled)
    }
    
    var unfollowButton: some View {
        Button {
            viewModel.unfollowButtonPressed()
        } label: {
            Text(Strings.CompleteSearchView.unfollowButtonTitle)
                .font(Fonts.muliBoldHeading1)
        }
        .buttonStyle(WhiteButtonStyle())
    }
}

#if DEBUG
struct CompleteScreen_Previews: PreviewProvider {
    static var previews: some View {
        CompleteScreen(session: .mock, exitRoute: { })
    }
}
#endif
