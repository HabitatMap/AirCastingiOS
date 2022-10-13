// Created by Lunar on 17/08/2022.
//

@testable import AirCasting

extension AlertInfo: Equatable {
    public static func == (lhs: AlertInfo, rhs: AlertInfo) -> Bool {
        lhs.id == rhs.id &&
        lhs.buttons == rhs.buttons
    }
}

extension AlertInfo.Button: Equatable {
    public static func == (lhs: AlertInfo.Button, rhs: AlertInfo.Button) -> Bool {
        switch (lhs, rhs) {
        case (.cancel(let lhsTitle), .cancel(let rhsTitle)): return lhsTitle == rhsTitle
        // We cannot really test action closure, but for unit testing it will be sufficient:
        case (.default(let lhsTitle, _), .default(let rhsTitle, _)): return lhsTitle == rhsTitle
        case (.cancel, .default): return false
        case (.default, .cancel): return false
        }
    }
}

