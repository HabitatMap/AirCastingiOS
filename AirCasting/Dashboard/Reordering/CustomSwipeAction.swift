// Created by Lunar on 29/08/2022.
//

import Foundation
import SwiftUI

// Adds custom swipe action to a given view
struct SwipeActionView: ViewModifier {
    let trailingAction: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var prevOffset: CGFloat = 0
    
    init(trailingAction: @escaping () -> Void) {
        self.trailingAction = trailingAction
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: (offset > 0) ? 0 : offset)
        // animate the view as `offset` changes
            .animation(.spring(), value: offset)
        // allows the DragGesture to work even if there are now interactable
        // views in the row
            .contentShape(Rectangle())
        // The DragGesture distates the swipe. The minimumDistance is there to
        // prevent the gesture from interfering with List vertical scrolling.
            .gesture(DragGesture(minimumDistance: 10,
                                 coordinateSpace: .local)
                .onChanged { gesture in
                    offset = gesture.translation.width
                }
                .onEnded { _ in
                    if !checkAndHandleFullSwipe(for: trailingAction, edge: .trailing, width: -UIScreen.main.bounds.size.width) {
                        offset = 0
                    }
                    prevOffset = offset
                })
    }
    
    // Checks if full swipe is supported and currently active for the given edge.
    // The current threshold is at half of the row width.
    private func fullSwipeEnabled(edge: Edge, width: CGFloat) -> Bool {
        let threshold = abs(width) / 2
        switch (edge) {
        case .leading:
            return offset > threshold
        case .trailing:
            return -offset > threshold
        }
    }
    
    // Checks if the view is in full swipe. If so, trigger the action
    private func checkAndHandleFullSwipe(for action: () -> Void,
                                         edge: Edge,
                                         width: CGFloat) -> Bool {
        if fullSwipeEnabled(edge: edge, width: width) {
            offset = width * 1.2
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                offset = 0
                prevOffset = 0
            }
            return true
        } else {
            return false
        }
    }
    
    private enum Edge {
        case leading, trailing
    }
}

extension View {
    func trailingSwipeAction(action: @escaping () -> Void) -> some View {
        modifier(SwipeActionView(trailingAction: action))
    }
}
