//
//  SessionCell.swift
//  AirCasting
//
//  Created by Lunar on 08/01/2021.
//

import SwiftUI
import CoreLocation
import CoreData
import Charts

struct SessionCellView: View {
    
    @State private var isCollapsed = true
    @State private var selectedStream: MeasurementStreamEntity?
    
    let session: SessionEntity
    let thresholds: [SensorThreshold]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            if let threshold = thresholdFor(selectedStream: selectedStream) {
                SessionHeaderView(
                    action:  {
                        withAnimation {
                            isCollapsed = !isCollapsed
                        }
                    }, isExpandButtonNeeded: true,
                    session: session,
                    threshold: threshold,
                    selectedStream: $selectedStream)
                
                if !isCollapsed {
                    VStack(alignment: .trailing, spacing: 40) {
                        if let selectedStream = selectedStream {
                            pollutionChart(stream: selectedStream,
                                           threshold: threshold)
                        }
                        displayButtons(threshold: threshold)
                    }
                }
            }
        }
        .onAppear {
            selectedStream = session.allStreams?.first
        }
        .font(Font.moderate(size: 13, weight: .regular))
        .foregroundColor(.aircastingGray)
        .padding()
        .background(
            Color.white
                .shadow(color: Color(red: 205/255, green: 209/255, blue: 214/255, opacity: 0.36), radius: 9, x: 0, y: 1)
        )
    }
}

private extension SessionCellView {
    
    func graphButton(threshold: SensorThreshold) -> some View {
        NavigationLink(destination: GraphView(session: session,
                                              threshold: threshold,
                                              selectedStream: $selectedStream)) {
            Text("graph")
        }
    }
    
    func mapButton(threshold: SensorThreshold) -> some View {
        NavigationLink(destination: AirMapView(threshold: threshold,
                                               session: session,
                                               selectedStream: $selectedStream)) {
            Text("map")
        }
    }
    
    func pollutionChart(stream: MeasurementStreamEntity, threshold: SensorThreshold) -> some View {
        Group {
            ChartView(stream: stream,
                      thresholds: threshold)
                .frame(height: 200)
        }
    }
    
    func displayButtons(threshold: SensorThreshold) -> some View {
        HStack(spacing: 20){
            mapButton(threshold: threshold)
            graphButton(threshold: threshold)
        }
        .buttonStyle(GrayButtonStyle())
    }
    
    func thresholdFor(selectedStream: MeasurementStreamEntity?) -> SensorThreshold? {
        thresholds.first { threshold in
            let streamName = selectedStream?.sensorName?
                .drop { $0 != "-" }
                .replacingOccurrences(of: "-", with: "")
                .lowercased()
            return threshold.sensorName?.lowercased() == streamName
        }
    }
}

#if DEBUG
struct SessionCell_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
        SessionCellView(session: SessionEntity.mock, thresholds: [.mock, .mock])
            .padding()
            .previewLayout(.sizeThatFits)
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
}
#endif
