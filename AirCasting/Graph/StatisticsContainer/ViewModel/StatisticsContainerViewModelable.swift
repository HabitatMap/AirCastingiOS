// Created by Lunar on 07/07/2021.
//

import Foundation

struct SingleStatViewModel: Identifiable {
    enum PresentationStyle {
        case standard
        case distinct
    }

    let id: Int
    let title: String
    let value: Double
    let presentationStyle: PresentationStyle
}

protocol StatisticsContainerViewModelable: ObservableObject {
    var stats: [SingleStatViewModel] { get }
    /// When continous mode is enabled it will allow for a time-based stats refreshing
    var continuousModeEnabled: Bool { get set }
    func adjustForNewData()
}
