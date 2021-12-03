import UIKit
import FirebaseRemoteConfig

class FirebaseFeatureFlagProvider: FeatureFlagProvider {
    var onFeatureListChange: (() -> Void)?
    
    private let notificationsRouter: RemoteNotificationRouter
    private var remoteNotificationsToken: RemoteNotificationRouter.Token!
    
    private let expirationDuration: TimeInterval = 43200 // 12hs
    private let messageIdentifier = "feature_flags_status"
    private static let userDefaultsErrorKey = "firebase_config_error"
    private var isInErrorState: Bool = UserDefaults.standard.bool(forKey: FirebaseFeatureFlagProvider.userDefaultsErrorKey) {
        didSet {
            UserDefaults.standard.set(isInErrorState, forKey: FirebaseFeatureFlagProvider.userDefaultsErrorKey)
        }
    }
    
    init(notificationsRouter: RemoteNotificationRouter) {
        self.notificationsRouter = notificationsRouter
        self.remoteNotificationsToken = notificationsRouter.register { [unowned self] userInfo, callback in
            guard let status = userInfo[self.messageIdentifier] as? String, status == "STALE" else { return }
            Log.info("firebase configuration changed!")
            UserDefaults.standard.set(true, forKey: "needs_config_refresh")
            callback()
        }
        setupForegroundObserving()
        fetchConfiguration(expirationDuration: expirationDuration)
    }
    
    deinit {
        notificationsRouter.unregister(token: remoteNotificationsToken)
    }
    
    func isFeatureOn(_ feature: FeatureFlag) -> Bool? {
        guard !isInErrorState else { return nil }
        let key = getFirebaseKey(for: feature)
        let config = RemoteConfig.remoteConfig().configValue(forKey: key)
        guard config.source == .remote else { return nil }
        return config.boolValue
    }
    
    private func getFirebaseKey(for feature: FeatureFlag) -> String {
        switch feature {
        case .sdCardSync: return "sd_card_sync"
        case .standaloneMode: return "standalone_mode"
        }
    }
    
    private func setupForegroundObserving() {
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [unowned self] _ in
            if UserDefaults.standard.bool(forKey: "needs_config_refresh") {
                Log.info("Config needs refresh detected")
                fetchConfiguration(expirationDuration: 0)
            }
        }
    }
    
    private func fetchConfiguration(expirationDuration: TimeInterval) {
        Log.info("starting config fetch")
        RemoteConfig.remoteConfig().fetch(withExpirationDuration: expirationDuration, completionHandler: { [weak self] status, error in
            Log.info("remote config fetch state: \(status.toString)")
            switch status {
            case .success: self?.activateConfig()
            case .failure:
                Log.error("Couldnt download firebase config: \(error?.localizedDescription ?? "none")")
                self?.isInErrorState = true
                return
            case .noFetchYet, .throttled: return
            @unknown default: fatalError()
            }
        })
    }
    
    private func activateConfig() {
        RemoteConfig.remoteConfig().activate(completion: { [weak self] hasChanged, error in
            guard hasChanged else {
                Log.info("remote config was not changed")
                return
            }
            guard error == nil else {
                Log.error("Cannot activate firebase config: \(error!.localizedDescription)")
                self?.isInErrorState = true
                return
            }
            self?.isInErrorState = false
            Log.info("firebase config changed, update finished")
            DispatchQueue.main.async { self?.onFeatureListChange?() }
        })
    }
}

extension RemoteConfigFetchStatus {
    var toString: String {
        switch self {
        case .failure: return "failure"
        case .noFetchYet: return "noFetchYet"
        case .success: return "success"
        case .throttled: return "throttled"
        @unknown default: fatalError()
        }
    }
}
