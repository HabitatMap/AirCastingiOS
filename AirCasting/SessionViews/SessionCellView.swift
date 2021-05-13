//
//  SessionCell.swift
//  AirCasting
//
//  Created by Lunar on 08/01/2021.
//

import SwiftUI
import CoreLocation
import CoreData

struct SessionCellView: View {
    
    @State private var isCollapsed = true
    @StateObject var provider = LocationTracker()
    let session: Session
    @FetchRequest<SensorThreshold>(sortDescriptors: [.init(key: "sensorName", ascending: true)]) var thresholds
    
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
                    pollutionChart
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
    
    var pathPoints: [PathPoint] {
        let allLocationPoints = provider.allLocations
        let points = allLocationPoints.map { (location) in
            PathPoint(location: location.coordinate,
                      measurement: Float(-10))
        }
        return points
    }
    
    var pollutionChart: some View {
        ChartView()
            .frame(height: 200)
    }
    var graphButton: some View {
        NavigationLink(destination: GraphView(thresholds: Array(thresholds))) {
            Text("graph")
        }
    }
    
    var mapButton: some View {
        NavigationLink(destination: AirMapView(thresholds: Array(thresholds),
                                               pathPoints: pathPoints)) {
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
}

#if DEBUG
struct SessionCell_Previews: PreviewProvider {
    static var previews: some View {
        SessionCellView(session: Session.mock)
            .padding()
            .previewLayout(.sizeThatFits)
            .environmentObject(MicrophoneManager())
    }
}
#endif
