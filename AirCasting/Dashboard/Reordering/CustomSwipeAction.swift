// Created by Lunar on 29/08/2022.
//

import Foundation
import SwiftUI

struct SwipeActionButton: View, Identifiable {
  static let width: CGFloat = 70

  let id = UUID()
  let text: Text?
  let icon: Image?
  let action: () -> Void
  let tint: Color?

  init(text: Text? = nil,
       icon: Image? = nil,
       action: @escaping () -> Void,
       tint: Color? = nil) {
    self.text = text
    self.icon = icon
    self.action = action
    self.tint = tint ?? .gray
  }

  var body: some View {
    ZStack {
      tint
      VStack {
        icon?
          .foregroundColor(.white)
        if icon == nil {
          text?
            .foregroundColor(.white)
        }
      }
      .frame(width: SwipeActionButton.width)
    }
  }
}

// Adds custom swipe actions to a given view
struct SwipeActionView: ViewModifier {
  // How much does the user have to swipe at least to reveal buttons on either side
  private static let minSwipeableWidth = SwipeActionButton.width * 0.8

  // Buttons at the leading (left-hand) side
  let leading: [SwipeActionButton]
  // Can you full swipe the leading side
  let allowsFullSwipeLeading: Bool
  // Buttons at the trailing (right-hand) side
  let trailing: [SwipeActionButton]
  // Can you full swipe the trailing side
  let allowsFullSwipeTrailing: Bool

  private let totalLeadingWidth: CGFloat!
  private let totalTrailingWidth: CGFloat!

  @State private var offset: CGFloat = 0
  @State private var prevOffset: CGFloat = 0

  init(leading: [SwipeActionButton] = [],
       allowsFullSwipeLeading: Bool = false,
       trailing: [SwipeActionButton] = [],
       allowsFullSwipeTrailing: Bool = false) {
    self.leading = leading
    self.allowsFullSwipeLeading = allowsFullSwipeLeading && !leading.isEmpty
    self.trailing = trailing
    self.allowsFullSwipeTrailing = allowsFullSwipeTrailing && !trailing.isEmpty
    totalLeadingWidth = SwipeActionButton.width * CGFloat(leading.count)
    totalTrailingWidth = SwipeActionButton.width * CGFloat(trailing.count)
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
            if !checkAndHandleFullSwipe(for: trailing, edge: .trailing, width: -UIScreen.main.bounds.size.width) {
            offset = 0
          }
          prevOffset = offset
        })
//    }
    // Remove internal row padding to allow the buttons to occupy full row height
//    .listRowInsets(EdgeInsets())
  }

  // Checks if full swipe is supported and currently active for the given edge.
  // The current threshold is at half of the row width.
  private func fullSwipeEnabled(edge: Edge, width: CGFloat) -> Bool {
    let threshold = abs(width) / 2
    switch (edge) {
    case .leading:
      return allowsFullSwipeLeading && offset > threshold
    case .trailing:
      return allowsFullSwipeTrailing && -offset > threshold
    }
  }

  // Creates the view for each SwipeActionButton. Also assigns it
  // a tap gesture to handle the click and reset the offset.
  private func button(for button: SwipeActionButton?) -> some View {
    button?
      .onTapGesture {
        button?.action()
        offset = 0
        prevOffset = 0
      }
  }

  // Calculates width for each button, proportional to the swipe.
  private func individualButtonWidth(edge: Edge) -> CGFloat {
    switch edge {
    case .leading:
      return (offset > 0) ? (offset / CGFloat(leading.count)) : 0
    case .trailing:
      return (offset < 0) ? (abs(offset) / CGFloat(trailing.count)) : 0
    }
  }

  // Checks if the view is in full swipe. If so, trigger the action on the
  // correct button (left- or right-most one), make it full the entire row
  // and schedule everything to be reset after a while.
  private func checkAndHandleFullSwipe(for collection: [SwipeActionButton],
                                       edge: Edge,
                                       width: CGFloat) -> Bool {
    if fullSwipeEnabled(edge: edge, width: width) {
      offset = width * CGFloat(collection.count) * 1.2
      ((edge == .leading) ? collection.first : collection.last)?.action()
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
  func swipeActions(leading: [SwipeActionButton] = [],
                    allowsFullSwipeLeading: Bool = false,
                    trailing: [SwipeActionButton] = [],
                    allowsFullSwipeTrailing: Bool = false) -> some View {
    modifier(SwipeActionView(leading: leading,
                             allowsFullSwipeLeading: allowsFullSwipeLeading,
                             trailing: trailing,
                             allowsFullSwipeTrailing: allowsFullSwipeTrailing))
  }
}
