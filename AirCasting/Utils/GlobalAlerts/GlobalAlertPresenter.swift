// Created by Lunar on 18/08/2022.
//

import Foundation


/// An alert button type used by the `GlobalAlertPresenter`
struct GlobalAlertButton {
    /// Button text
    let title: String
    /// Button action handler
    let onTap: (() -> Void)?
}

/// Represents objects capable of showing alerts.
/// The reason this was created is that both UIKit's and SwiftUI's alerts are bound to view/controller
/// hierarchies. The app however sometimes needs to present alerts regardless of where the user
/// currently is navigation wise.
/// notes:
///     1. Technically this should allow for stacking alerts, but in current implementation this has not
///     been tested.
protocol GlobalAlertPresenter {
    /// Shows a navigation/UI independent alert on the screen
    /// - Parameters:
    ///   - title: the alert title
    ///   - text: the alert body
    ///   - buttonTitle: a dismiss button title.
    func showAlert(title: String, text: String, buttons: [GlobalAlertButton])
}

// MARK: Adapters

extension GlobalAlertPresenter {
    func present(alert: AlertInfo) {
        showAlert(title: alert.title, text: alert.message, buttons: alert.globalAlertStyleButtons)
    }
}

extension AlertInfo {
    var globalAlertStyleButtons: [GlobalAlertButton] {
        buttons.map(\.globalAlertStyle)
    }
}

extension AlertInfo.Button {
    var globalAlertStyle: GlobalAlertButton {
        switch self {
        case .cancel(let title): return .init(title: title, onTap: nil)
        case .default(let title, let action): return .init(title: title, onTap: action)
        }
    }
}
