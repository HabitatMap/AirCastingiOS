// Created by Lunar on 11/11/2021.
//

import SwiftUI

struct RefreshControl: View {
    let coordinateSpace: CoordinateSpace
    @Binding var isRefreshing: Bool
    
    private let pullToRefreshThreshold: CGFloat = 50
    
    var body: some View {
        GeometryReader { geometry in
            if shouldStartRefreshing(using: geometry) {
                startRefreshing()
            }
            ZStack(alignment: .center) {
                if isRefreshing { ProgressView(Strings.RefreshControl.progressViewText) } else { mimicPullToRefreshAnimation(with: geometry) }
            }
            .frame(width: geometry.size.width)
        }
        // paddings: for non-refreshing state we need negative top padding to hide
        // the refresh control correctly under the top part of a parent view.
        //
        // Values here are handpicked using the eye-ball technique 👀
        .padding(.top, isRefreshing ? 8 : -30)
        .padding(.bottom, isRefreshing ? 40 : 1)
    }
    
    private func shouldStartRefreshing(using geometry: GeometryProxy) -> Bool {
        geometry.frame(in: coordinateSpace).midY > pullToRefreshThreshold
    }
    
    private func startRefreshing() -> some View {
        Spacer()
            .onAppear {
                guard isRefreshing == false else { return }
                isRefreshing = true
            }
    }
    
    private func mimicPullToRefreshAnimation(with geometry: GeometryProxy) -> some View {
        ForEach(0..<8) { tick in
            VStack {
                Rectangle()
                    .fill(Color(.tertiaryLabel))
                    .opacity(opacity(for: tick, with: geometry))
                    .frame(width: 3, height: 7)
                    .cornerRadius(3)
                Spacer()
            }
            .rotationEffect(.degrees(Double(tick)/8 * 360))
        }
        .frame(width: 20, height: 20, alignment: .center)
    }
    
    private func opacity(for tick: Int, with geometry: GeometryProxy) -> Double {
        let midY = geometry.frame(in: coordinateSpace).midY
        return (Int(midY / 7) < tick) ? 0 : 1
    }
}
