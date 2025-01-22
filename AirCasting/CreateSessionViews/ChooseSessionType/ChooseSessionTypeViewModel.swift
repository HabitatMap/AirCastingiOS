// Created by Lunar on 02/08/2021.
//

import Foundation
import Resolver

enum ProceedToView {
    case airBeam
    case location
    case bluetooth
    case mobile
}

class ChooseSessionTypeViewModel: ObservableObject {
    @Published var isSearchAndFollowLinkActive = false {
        didSet {
            Log.info("MARTA: isSearchAndFollowLinkActive changed")
        }
    }
    @Published var isTurnLocationOnLinkActive = false {
        didSet {
            Log.info("MARTA: isTurnLocationOnLinkActive changed")
        }
    }
    @Published var isMobileLinkActive = false {
        didSet {
            Log.info("MARTA: isMobileLinkActive changed")
        }
    }
    @Published var isTurnBluetoothOnLinkActive = false {
        didSet {
            Log.info("MARTA: isTurnBluetoothOnLinkActive changed")
        }
    }
    @Published var isPowerABLinkActive = false {
        didSet {
            Log.info("MARTA: isPowerABLinkActive changed")
        }
    }
    @Published var startSync = false {
        didSet {
            Log.info("MARTA: startSync changed")
        }
    }
    @Published var isInfoPresented: Bool = false {
        didSet {
            Log.info("MARTA: isInfoPresented changed")
        }
    } 
    @Published var alert: AlertInfo? {
        didSet {
            Log.info("MARTA: alert changed")
        }
    }
    @Injected private var networkChecker: NetworkChecker {
        didSet {
            Log.info("MARTA: networkChecker changed")
        }
    }
    @Injected private var locationAuthorization: LocationAuthorization {
        didSet {
            Log.info("MARTA: locationAuthorization changed")
        }
    }
    @Injected private var bluetoothHandler: BluetoothPermisionsChecker {
        didSet {
            Log.info("MARTA: bluetoothHandler changed")
        }
    }
    @InjectedObject private var userSettings: UserSettings {
        didSet {
            Log.info("MARTA: userSettings changed")
        }
    }
    @Injected private var urlProvider: URLProvider {
        didSet {
            Log.info("MARTA: urlProvider changed")
        }
    }
    private let sessionContext: CreateSessionContext
    
    var passSessionContext: CreateSessionContext {
        return sessionContext
    }
    
    init(sessionContext: CreateSessionContext) {
        self.sessionContext = sessionContext
    }
    
    func setSearchAndFollow(using new: Bool) { DispatchQueue.main.async { self.isSearchAndFollowLinkActive = new }}
    func setInfoPresented(using new: Bool) { DispatchQueue.main.async { self.isInfoPresented = new }}
    func setStartSync(using new: Bool) { DispatchQueue.main.async { self.startSync = new }}
    func setPowerABLink(using new: Bool) { DispatchQueue.main.async { self.isPowerABLinkActive = new }}
    func setBluetoothLink(using new: Bool) { DispatchQueue.main.async { self.isTurnBluetoothOnLinkActive = new }}
    func setMobileLink(using new: Bool) { DispatchQueue.main.async { self.isMobileLinkActive = new } }
    func setLocationLink(using new: Bool) { DispatchQueue.main.async { self.isTurnLocationOnLinkActive = new }}
    
    func handleMobileSessionState() {
        createNewSession(isSessionFixed: false)
        switch mobileSessionNextStep() {
        case .location: isTurnLocationOnLinkActive = true
        case .mobile: isMobileLinkActive = true
        default: return
        }
    }
    
    func fixedSessionButtonTapped() {
        createNewSession(isSessionFixed: true)
        switch fixedSessionNextStep() {
        case .airBeam: isPowerABLinkActive = true
        case .bluetooth: isTurnBluetoothOnLinkActive = true
        default: return
        }
    }
    
    func mobileSessionButtonTapped() {
        handleMobileSessionState()
    }
    
    func syncButtonTapped() {
        guard !userSettings.syncOnlyThroughWifi || networkChecker.isUsingWifi else {
            alert = InAppAlerts.noWifiNetworkSyncAlert()
            return
        }
        networkChecker.connectionAvailable ? startSync.toggle() : (alert = InAppAlerts.noNetworkAlert())
    }
    
    func infoButtonTapped() {
        isInfoPresented = true
    }
    
    func searchAndFollowTapped() {
       isSearchAndFollowLinkActive = true
    }
    
    // MARK: - Private methods
    private func createNewSession(isSessionFixed: Bool) {
        sessionContext.sessionUUID = SessionUUID()
        if isSessionFixed {
            sessionContext.contribute = true
            sessionContext.sessionType = SessionType.fixed
        } else {
            sessionContext.contribute = userSettings.contributingToCrowdMap
            sessionContext.locationless = userSettings.disableMapping
            sessionContext.sessionType = SessionType.mobile
        }
    }
    
    private func fixedSessionNextStep() -> ProceedToView {
        guard !bluetoothHandler.isBluetoothDenied() else { return .bluetooth }
        return .airBeam
    }
    
    private func mobileSessionNextStep() -> ProceedToView {
        let isLocationDenied = locationAuthorization.locationState != .granted
        return !userSettings.disableMapping && isLocationDenied ? .location : .mobile
    }
}
