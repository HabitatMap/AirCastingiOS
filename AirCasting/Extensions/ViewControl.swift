// Created by Lunar on 11/02/2022.
//

import SwiftUI

extension View {
    func onAppCameToForeground(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            action()
        }
    }

    func onAppWentToBackground(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            action()
        }
    }
    
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}
