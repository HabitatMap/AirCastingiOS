// Created by Lunar on 29/08/2022.
//

import Foundation
import SwiftUI

/// Adds custom swipe action to a given view
struct SwipeActionView: ViewModifier {
    let action: () -> Void
    
    @State private var offset: CGFloat = 0
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
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
                    if offset < 0 {
                        checkAndHandleFullSwipe(for: action, edge: .trailing, width: -UIScreen.main.bounds.size.width)
                    } else {
                        checkAndHandleFullSwipe(for: action, edge: .leading, width: UIScreen.main.bounds.size.width)
                    }
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
                                         width: CGFloat) {
        if fullSwipeEnabled(edge: edge, width: width) {
            offset = width * 1.2
            action()
        } else {
            offset = 0
        }
    }
    
    private enum Edge {
        case leading, trailing
    }
}

extension View {
    func swipeAction(action: @escaping () -> Void) -> some View {
        modifier(SwipeActionView(action: action))
    }
}
