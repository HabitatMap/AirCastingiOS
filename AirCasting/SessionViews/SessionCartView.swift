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
    @State private var isCollapsed = true
    @State private var selectedStream: MeasurementStreamEntity?
    @ObservedObject var session: SessionEntity
    let sessionCartViewModel: SessionCartViewModel
    let thresholds: [SensorThreshold]
    let sessionStoppableFactory: SessionStoppableFactory
    
    var shouldShowValues: MeasurementPresentationStyle {
        let shouldShow = isCollapsed && (session.isFixed || session.isDormant)
        return shouldShow ? .hideValues : .showValues
    }

    var showChart: Bool {
        !isCollapsed && session.type == .mobile && session.status == .RECORDING
    }
    var hasStreams: Bool {
        session.allStreams != nil || session.allStreams != []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            header
            if hasStreams {
                StreamsView(selectedStream: $selectedStream,
                            session: session,
                            thresholds: thresholds,
                            measurementPresentationStyle: shouldShowValues)

                VStack(alignment: .trailing, spacing: 40) {
                    if showChart {
                        pollutionChart(thresholds: thresholds)
                    }
                    if !isCollapsed {
                        displayButtons(thresholds: thresholds)
                    }
                }
            } else {
                SessionLoadingView()
            }
        }
        .onChange(of: session.allStreams) { _ in
            selectedStream = session.allStreams?.first
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
            isCollapsed: $isCollapsed,
            session: session,
            sessionStopperFactory: sessionStoppableFactory
        )
    }
    
    func graphButton(thresholds: [SensorThreshold]) -> some View {
        NavigationLink(destination: GraphView(session: session,
                                              thresholds: thresholds,
                                              selectedStream: $selectedStream,
                                              sessionStoppableFactory: sessionStoppableFactory)) {
            Text(Strings.SessionCartView.graph)
        }
    }
    
    func mapButton(thresholds: [SensorThreshold]) -> some View {
        NavigationLink(destination: AirMapView(thresholds: thresholds,
                                               session: session,
                                               selectedStream: $selectedStream,
                                               sessionStoppableFactory: sessionStoppableFactory)) {
            Text(Strings.SessionCartView.map)
        }
    }
    
    var followButton: some View {
        Button(Strings.SessionCartView.follow) {
            sessionCartViewModel.toggleFollowing()
        }.buttonStyle(FollowButtonStyle())
    }
    
    var unFollowButton: some View {
        Button(Strings.SessionCartView.unfollow) {
            sessionCartViewModel.toggleFollowing()
        }.buttonStyle(UnFollowButtonStyle())
    }
    
    func pollutionChart(thresholds: [SensorThreshold]) -> some View {
        Group {
            if let selectedStream = selectedStream {
                ChartView(stream: selectedStream,
                          thresholds: thresholds)
                    .frame(height: 200)
            }
        }
    }
    
    func displayButtons(thresholds: [SensorThreshold]) -> some View {
        HStack(spacing: 20) {
            if sessionCartViewModel.isFollowing && session.type == .fixed {
                unFollowButton
            } else if session.type == .fixed {
                followButton
            }
            Spacer()
            if !session.isIndoor && session.type != .fixed {
                mapButton(thresholds: thresholds)
            }
            graphButton(thresholds: thresholds)
        }
        .buttonStyle(GrayButtonStyle())
    }
}

 #if DEBUG
 struct SessionCell_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
        SessionCartView(session: SessionEntity.mock,
                                sessionCartViewModel: SessionCartViewModel(followingSetter: MockSessionFollowingSettable()),
                                thresholds: [.mock, .mock], sessionStoppableFactory: SessionStoppableFactoryDummy())
            .padding()
            .previewLayout(.sizeThatFits)
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
 }
 #endif
