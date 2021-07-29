//
//  SessionCell.swift
//  AirCasting
//
//  Created by Lunar on 08/01/2021.
//

import AirCastingStyling
import Charts
import CoreData
import CoreLocation
import SwiftUI

struct SessionCartView: View {
    @State private var isFollowing = false
    @State private var isCollapsed = true
    @State private var selectedStream: MeasurementStreamEntity?
    @ObservedObject var session: SessionEntity
    @EnvironmentObject var sessionCartViewModel: SessionCartViewModel
    let thresholds: [SensorThreshold]
    
    var shouldShowValues: MeasurementPresentationStyle {
        let isFixed = session.type == .fixed
        let isDormant = session.type == .mobile && session.status == .FINISHED
        let shouldShow = isCollapsed && (isFixed || isDormant)
        
        return shouldShow ? .hideValues : .showValues
    }

    var showChart: Bool {
        !isCollapsed && session.type == .mobile && session.status == .RECORDING
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            header
            if let threshold = thresholdFor(selectedStream: selectedStream) {
                StreamsView(selectedStream: $selectedStream,
                            session: session,
                            threshold: threshold,
                            measurementPresentationStyle: shouldShowValues)
            
                VStack(alignment: .trailing, spacing: 40) {
                    if let selectedStream = selectedStream, showChart {
                        pollutionChart(stream: selectedStream,
                                       threshold: threshold)
                    }
                    if !isCollapsed {
                        displayButtons(threshold: threshold)
                    }
                }
            } else {
                SessionLoadingView()
            }
        }
        .onChange(of: session.allStreams) { _ in
            selectedStream = session.allStreams?.first
        }
        .onChange(of: isFollowing) { _ in
            if isFollowing {
                sessionCartViewModel.makeFollowing(for: session)
            } else {
                sessionCartViewModel.makeNotFollowing(for: session)
            }
        }
        .onAppear {
            if session.followedAt != nil {
                isFollowing = true
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

private extension SessionCartView {
    var header: some View {
        SessionHeaderView(
            action: {
                withAnimation {
                    isCollapsed.toggle()
                }
            }, isExpandButtonNeeded: true,
            session: session
        )
    }
    
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
    
    var followButton: some View {
        Button("follow") {
            isFollowing.toggle()
        }.buttonStyle(FollowButtonStyle())
    }
    
    var unFollowButton: some View {
        Button("unfollow") {
            isFollowing.toggle()
        }.buttonStyle(UnFollowButtonStyle())
    }
    
    func pollutionChart(stream: MeasurementStreamEntity, threshold: SensorThreshold) -> some View {
        Group {
            ChartView(stream: stream,
                      thresholds: threshold)
                .frame(height: 200)
        }
    }
    
    func displayButtons(threshold: SensorThreshold) -> some View {
        HStack(spacing: 20) {
            if isFollowing {
                unFollowButton
            } else if session.type == .fixed, !isFollowing {
                followButton
            }
            Spacer()
            mapButton(threshold: threshold)
            graphButton(threshold: threshold)
        }
        .buttonStyle(GrayButtonStyle())
    }
    
    func thresholdFor(selectedStream: MeasurementStreamEntity?) -> SensorThreshold? {
        let match = thresholds.first { threshold in
            let streamName = selectedStream?.sensorName?
                .lowercased()
            return threshold.sensorName?.lowercased() == streamName
        }
        return match
    }
}

 #if DEBUG
 struct SessionCell_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
        SessionCartView(session: SessionEntity.mock, thresholds: [.mock, .mock])
            .padding()
            .previewLayout(.sizeThatFits)
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
 }
 #endif
