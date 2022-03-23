// Created by Lunar on 03/03/2022.
//

import Foundation
import Resolver

class PrivacyOnboardingViewModel {
    @Injected private var networkChecker: NetworkChecker
    @Published var showWebView = false
    @Published var isInfoPresented: Bool = false
    @Published var alert: AlertInfo?

    func learnMoreButtonTapped() {
        networkChecker.connectionAvailable ? showWebView.toggle() : (alert = InAppAlerts.noNetworkAlert())
    }
}
