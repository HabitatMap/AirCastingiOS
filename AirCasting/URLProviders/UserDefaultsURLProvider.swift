// Created by Lunar on 28/06/2021.
//

import Foundation

class UserDefaultsURLProvider: URLProvider {
    private static let defaultBaseURL = URL(string: "https://aircasting.org/")!

    /// Hosts earlier dev builds defaulted to. Rewrite any persisted
    /// experimental / legacy host on launch so the iOS app and the AirBeam
    /// Mini firmware agree on the production backend for V2 fixed sessions.
    private static let migrateAwayFromHosts: Set<String> = [
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
        // Always force the production + HTTPS canonical form on upgrade.
        if stored != Self.defaultBaseURL {
            userDefaults.set(Self.defaultBaseURL, forKey: "baseURL")
        }
    }
}
