// Created by Lunar on 10/11/2021.
//
import Foundation
import SystemConfiguration.CaptiveNetwork
import Resolver

/// Discrete preset options shown in the V2 mobile-session interval wheel picker.
/// Backed by raw seconds so it can be lifted straight onto the wire payload
/// (`V2BinaryProtocol.buildNewSessionConfigMobile(uuid:interval:)`).
enum MobileMeasurementInterval: Int, CaseIterable, Identifiable {
    case oneSecond   = 1
    case fiveSeconds = 5
    case oneMinute   = 60
    case fiveMinutes = 300
    case tenMinutes  = 600

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .oneSecond:   return Strings.CreateSessionDetailsView.interval1Second
        case .fiveSeconds: return Strings.CreateSessionDetailsView.interval5Seconds
        case .oneMinute:   return Strings.CreateSessionDetailsView.interval1Minute
        case .fiveMinutes: return Strings.CreateSessionDetailsView.interval5Minutes
        case .tenMinutes:  return Strings.CreateSessionDetailsView.interval10Minutes
        }
    }
}

class CreateSessionDetailsViewModel: ObservableObject {

    @Published var sessionName: String = ""
    @Published var sessionTags: String = ""
    /// Bound to the wheel picker on the V2 mobile new-session screen. Defaults to 1s.
    @Published var measurementInterval: MobileMeasurementInterval = .oneSecond
    @Published var isIndoor = true
    @Published var isWiFi = true
    @Published var wifiPassword: String = ""
    @Published var wifiSSID: String = ""
    @Published var isConfirmCreatingSessionActive: Bool = false
    @Published var isLocationSessionDetailsActive: Bool = false
    @Published var isLocationScreenNedeed: Bool = false
    @Published var showAlertAboutEmptyCredentials = false
    @Published var showErrorIndicator: Bool = false
    @Published var showWifiPasswordField = true
    var shouldShowError: Bool { sessionName.isEmpty && showErrorIndicator }
    @Injected private var locationAuthorization: LocationAuthorization
    
    private let keychainStorage = KeychainStorage(service: Bundle.main.bundleIdentifier!)
    private let wifiSsidKey = "StoredWifiName"
    
    func onScreenEnter() {
        if let ssid = try? keychainStorage.string(forKey: wifiSsidKey){
            wifiSSID = ssid
            if let data = try? keychainStorage.data(forKey: ssid), let password = String(data: data, encoding: .utf8) {
                wifiPassword = password
                showWifiPasswordField = false
            }
        }
    }
    
    func updatePasswordTapped() {
        showWifiPasswordField = true
    }
    
    func onContinueClick(sessionContext: CreateSessionContext) -> CreateSessionContext {
        saveWifiNameAndPassword()
        // sessionContext is needed because it is being modified in the session creation proccess
        // by 'modified' I mean - the data it ovverriden by the proper one (get from user) on every step
        guard !sessionName.isEmpty else { showErrorIndicator = true; return sessionContext }
        sessionContext.sessionName = sessionName
        sessionContext.sessionTags = sessionTags

        guard sessionContext.sessionType == .fixed else {
            // V2-mobile-only: thread the user-picked native interval (seconds, ≥ 1)
            // through CreateSessionContext → MobilePeripheralSessionCreator →
            // V2 NewSessionConfig payload. V1 firmware has no opcode for a configurable
            // interval and fixed sessions hard-code 60s, so leave `intervalSeconds` nil
            // on those paths — the DB column stays unset and the averaging gate falls
            // back to its 1s-native default.
            if sessionContext.device?.firmwareVersion == .v2 {
                sessionContext.intervalSeconds = measurementInterval.rawValue
            }
            sessionContext.isIndoor = false
            isConfirmCreatingSessionActive = true
            return sessionContext
        }
        sessionContext.ovverride(sessionContext: checkIfWiFi(sessionContext: sessionContext))
        sessionContext.ovverride(sessionContext: compareIsIndoor(sessionContext: sessionContext))
        return sessionContext
    }
    
    private func saveWifiNameAndPassword() {
        // We only want to save password for the default wifi network
        guard !wifiPassword.isEmpty else { return }
        guard let passwordData = wifiPassword.data(using: .utf8) else { return }
        do {
            try keychainStorage.setValue(value: passwordData, forKey: wifiSSID)
            try keychainStorage.setString(wifiSSID, forKey: wifiSsidKey)
        } catch {
            Log.error("Failed to save wifi password to the keychain")
        }
    }
    
    private func checkIfWiFi(sessionContext: CreateSessionContext) -> CreateSessionContext {
        if isWiFi, !(areCredentialsEmpty()) {
            sessionContext.wifiSSID = wifiSSID
            sessionContext.wifiPassword = wifiPassword
        } else if areCredentialsEmpty() {
            showAlertAboutEmptyCredentials = true
        } else if !isWiFi {
            // to be able to check if session is cellular
            sessionContext.wifiSSID = nil
            sessionContext.wifiPassword = nil
        }
        return sessionContext
    }
    
    private func compareIsIndoor(sessionContext: CreateSessionContext) -> CreateSessionContext {
        sessionContext.isIndoor = isIndoor
        guard locationAuthorization.locationState == .denied && !isIndoor else {
            isLocationSessionDetailsActive = !isIndoor
            isConfirmCreatingSessionActive = isIndoor
            return sessionContext
        }
        isLocationScreenNedeed = true
        return sessionContext
    }
    
    func areCredentialsEmpty() -> Bool {
        isWiFi && wifiSSID.isEmpty && wifiPassword.isEmpty
    }
    
    func isMiniSession(sessionContext: CreateSessionContext) -> Bool {
        sessionContext.device?.name?.starts(with: "AirBeamMini") ?? false
    }
    
    func shouldShowCompleteCredentials() -> Bool {
        isWiFi
    }
}
