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

    let session: SessionEntity
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
                    drawPollutionChart(stream: session.dbStream!)
                    buttons
                }
            }
        }
        .font(Font.moderate(size: 13, weight: .regular))
        .foregroundColor(.aircastingGray)
        .padding()
        .background(
            Color.random
//            Color.white
                .shadow(color: Color(red: 205/255, green: 209/255, blue: 214/255, opacity: 0.36), radius: 9, x: 0, y: 1)
        )
    }
}

private extension SessionCellView {
    var pollutionChart: some View {
        ChartView()
            .frame(height: 200)
    }
    var graphButton: some View {
        NavigationLink(destination: GraphView(thresholds: Array(thresholds), session: session)) {
            Text("graph")
        }
    }

    var mapButton: some View {
        NavigationLink(destination: AirMapView(thresholds: Array(thresholds), session: session)) {
            Text("map")
        }
    }
    var buttons: some View {
        HStack(spacing: 20){
            mapButton
            graphButton
        }
        .buttonStyle(GrayButtonStyle())
    }

    func drawPollutionChart(stream: MeasurementStreamEntity) -> some View {
        print("draw pollution stream was called for \(stream.session.name!)")
        let entries =  ChartEntriesCreator(session: session, stream: stream).generateEntries()
        return ChartView(entries: entries)
            .frame(height: 200)
            .background(Color.random)
    }
}

extension Color {
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
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
