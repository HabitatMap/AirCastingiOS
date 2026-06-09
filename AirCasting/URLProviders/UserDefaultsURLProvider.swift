// Created by Lunar on 28/06/2021.
//

import Foundation

class UserDefaultsURLProvider: URLProvider {
    private static let defaultBaseURL = URL(string: "https://aircasting.org/")!

    /// Hosts earlier dev builds defaulted to. The AirBeam Mini firmware has been
    /// flashed to point at `experimental.aircasting.org` for this branch, so the
    /// iOS app and the device must agree on experimental for V2 fixed sessions
    /// to work end-to-end. Rewrite any persisted prod/insecure URL on launch.
    private static let migrateAwayFromHosts: Set<String> = [
        "aircasting.org",
        "experimental.aircasting.org"
    ]

    var baseAppURL: URL {
        get {
            userDefaults.url(forKey: "baseURL") ?? Self.defaultBaseURL
        }
        set {
            userDefaults.set(newValue, forKey: "baseURL")
        }
    }

    private let userDefaults: UserDefaults
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        migrateLegacyHostIfNeeded()
    }

    private func migrateLegacyHostIfNeeded() {
        guard let stored = userDefaults.url(forKey: "baseURL"),
              let host = stored.host?.lowercased(),
              Self.migrateAwayFromHosts.contains(host) else { return }
        // Always force the experimental + HTTPS canonical form on upgrade.
        if stored != Self.defaultBaseURL {
            userDefaults.set(Self.defaultBaseURL, forKey: "baseURL")
        }
    }
}
