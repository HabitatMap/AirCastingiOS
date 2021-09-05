// Created by Lunar on 07/06/2021.
//

import SwiftUI
import AirCastingStyling
import CoreLocation
import CoreData

enum MeasurementPresentationStyle {
    case showValues
    case hideValues
}

struct ABMeasurementsView: View {
    @ObservedObject var session: SessionEntity
    @Binding var isCollapsed: Bool
    @Binding var selectedStream: MeasurementStreamEntity?
    @State private var showLoadingIndicator = true
    var thresholds: [SensorThreshold]
    let measurementPresentationStyle: MeasurementPresentationStyle
    let sessionDownloader = SessionDownloadService(client: URLSession.shared,
                                                   authorization: UserAuthenticationSession(),
                                                   responseValidator: DefaultHTTPResponseValidator())
    let measurementStreamStorage: MeasurementStreamStorage
    @EnvironmentObject var selectedSection: SelectSection

    private var streamsToShow: [MeasurementStreamEntity] {
        return session.sortedStreams ?? []
    }
    
    var body: some View {
        let streams = streamsToShow
        let hasAnyMeasurements = streams.filter { $0.latestValue != nil }.count > 0
        
        return Group {
            if hasAnyMeasurements {
                VStack(alignment: .leading, spacing: 5) {
                    measurementsTitle
                        .font(Font.moderate(size: 12))
                        .padding(.bottom, 3)
                    HStack {
                        Group {
                            ForEach(streams, id : \.self) { stream in
                                if let threshold = thresholds.threshold(for: stream) {
                                    SingleMeasurementView(stream: stream,
                                                          value: stream.latestValue ?? 0,
                                                          threshold: threshold,
                                                          selectedStream: _selectedStream,
                                                          measurementPresentationStyle: measurementPresentationStyle)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                if session.isFollowed {
                    SessionLoadingView()
                } else if session.isDormant {
                    VStack {
                        measurementsTitle
                        if !isCollapsed && showLoadingIndicator {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.SessionCart.parametersText)
                        HStack {
                            Group {
                                ForEach(streams, id : \.self) { stream in
                                    SingleMeasurementView(stream: stream,
                                                          value: nil,
                                                          threshold: nil,
                                                          selectedStream: .constant(nil),
                                                          measurementPresentationStyle: .hideValues)
                                }
                            }.padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .onChange(of: isCollapsed, perform: { _ in
            if isCollapsed == false && !hasAnyMeasurements {
                showLoadingIndicator = true
                sessionDownloader.downloadSessionWithMeasurement(uuid: session.uuid) { result in
                    switch result {
                    case .success(let data):
                        let dataBaseStreams = data.streams.values.map { value in
                            SynchronizationDataConterter().convertDownloadDataToDatabaseStream(data: value)
                        }
                        dataBaseStreams.forEach { stream in
                            stream.measurements.forEach { measurement in
                                let location: CLLocationCoordinate2D? = {
                                    guard let latitude = measurement.latitude,
                                          let longitude = measurement.longitude else { return CLLocationCoordinate2D(latitude: 200, longitude: 200) }
                                    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                }()
                                guard let streamID = try? measurementStreamStorage.existingMeasurementStream(session.uuid, name: stream.sensorName) else {
                                    Log.info("failed to get existing streamID for synced measurements from session \(String(describing: session.name))")
                                    return }
                                try? measurementStreamStorage.addMeasurement(Measurement(time: measurement.time, value: measurement.value, location: location), toStreamWithID: streamID)
                            }
                            try? measurementStreamStorage.saveThresholdFor(sensorName: stream.sensorName,
                                                                           thresholdVeryHigh: Int32(stream.thresholdVeryHigh),
                                                                           thresholdHigh: Int32(stream.thresholdHigh),
                                                                           thresholdMedium: Int32(stream.thresholdMedium),
                                                                           thresholdLow: Int32(stream.thresholdLow),
                                                                           thresholdVeryLow: Int32(stream.thresholdVeryLow))
                            
                        }
                        showLoadingIndicator = false
                    case .failure(let error):
                        Log.info("\(error)")
                    }
                }
            }
        })
    }
}

extension ABMeasurementsView {
    var measurementsTitle: some View {
        if session.deviceType == .MIC {
            return Text(verbatim: Strings.SessionCart.measurementsTitle)
        } else
        if session.isActive {
            return Text(Strings.SessionCart.measurementsTitle)
        } else if session.isDormant {
            if isCollapsed {
                return Text(Strings.SessionCart.parametersText)
            } else {
                return Text(Strings.SessionCart.dormantMeasurementsTitle)
            }
        } else if session.isFixed && !session.isFollowed {
            if isCollapsed {
                return Text(Strings.SessionCart.parametersText)
            } else {
                return Text(Strings.SessionCart.lastMinuteMeasurement)
            }
        } else if session.isFollowed {
            return Text(Strings.SessionCart.lastMinuteMeasurement)
        }
        return Text("")
    }
}

