// Created by Lunar on 21/07/2021.
//

import SwiftUI
// swiftlint:disable print_using
extension View {
    func Print(_ vars: Any...) -> some View {
        for v in vars { print(v) }
        return EmptyView()
    }
}
// swiftlint:enable print_using
