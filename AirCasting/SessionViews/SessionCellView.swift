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
    
    var session: SessionEntity
    let thresholds: [SensorThreshold]

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            SessionHeaderView(action:  {
                withAnimation {
                    isCollapsed = !isCollapsed
                }
            }, isExpandButtonNeeded: true,
            session: session,
            thresholds: Array(thresholds))
            if !isCollapsed {
                VStack(alignment: .trailing, spacing: 40) {
                    if let stream = session.dbStream {
                        pollutionChart(stream: stream)
                    }
                    buttons
                }
            }
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
    var graphButton: some View {
        NavigationLink(destination: GraphView(session: session, thresholds: Array(thresholds))) {
            Text("graph")
        }
    }
    
    var mapButton: some View {
        NavigationLink(destination: AirMapView(thresholds: Array(thresholds), session: session)) {
            Text("map")
        }
    }
    
    func pollutionChart(stream: MeasurementStreamEntity) -> some View {
        ChartView(stream: stream, thresholds: thresholds[0])
            .frame(height: 200)
    }
    
    var buttons: some View {
        HStack(spacing: 20){
            mapButton
            graphButton
        }
        .buttonStyle(GrayButtonStyle())
    }
}

#if DEBUG
struct SessionCell_Previews: PreviewProvider {
    static var previews: some View {
        SessionCellView(session: SessionEntity.mock, thresholds: [.mock, .mock])
            .padding()
            .previewLayout(.sizeThatFits)
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
}
#endif
