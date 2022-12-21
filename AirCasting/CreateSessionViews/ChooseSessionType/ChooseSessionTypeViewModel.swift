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
    @Published var isSearchAndFollowLinkActive = false
    @Published var isTurnLocationOnLinkActive = false
    @Published var isMobileLinkActive = false
    @Published var isTurnBluetoothOnLinkActive = false
    @Published var isPowerABLinkActive = false
    @Published var startSync = false
    @Published var isInfoPresented: Bool = false
    @Published var alert: AlertInfo?
    @Injected private var networkChecker: NetworkChecker
    @Injected private var locationAuthorization: LocationAuthorization
    @Injected private var bluetoothHandler: BluetoothPermisionsChecker
    @InjectedObject private var userSettings: UserSettings
    @Injected private var urlProvider: URLProvider
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
