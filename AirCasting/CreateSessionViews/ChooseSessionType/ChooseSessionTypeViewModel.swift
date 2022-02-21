// Created by Lunar on 02/08/2021.
//

import Foundation
import CoreBluetooth
import Resolver

enum ProceedToView {
    case airBeam
    case location
    case bluetooth
    case mobile
}

class ChooseSessionTypeViewModel: ObservableObject {
    @Published var isSearchAndFollow = false
    @Published var isTurnLocationOnLinkActive = false
    @Published var isMobileLinkActive = false
    @Published var isTurnBluetoothOnLinkActive = false
    @Published var isPowerABLinkActive = false
    @Published var startSync = false
    @Published var isInfoPresented: Bool = false
    @Published var alert: AlertInfo?
    @Injected private var networkChecker: NetworkChecker
    @Injected private var locationHandler: LocationHandler
    @Injected private var bluetoothHandler: BluetoothHandler
    @Injected private var userSettings: UserSettings
    @Injected private var urlProvider: URLProvider
    private let sessionContext: CreateSessionContext
    
    var passSessionContext: CreateSessionContext {
        return sessionContext
    }
    
    init(sessionContext: CreateSessionContext) {
        self.sessionContext = sessionContext
    }
    
    func setSearchAndFollow(using new: Bool) { isSearchAndFollow = new }
    func setInfoPresented(using new: Bool) { isInfoPresented = new }
    func setStartSync(using new: Bool) { startSync = new }
    func setPowerABLink(using new: Bool) { isPowerABLinkActive = new }
    func setBluetoothLink(using new: Bool) { isTurnBluetoothOnLinkActive = new }
    func setMobileLink(using new: Bool) { isMobileLinkActive = new }
    func setLocationLink(using new: Bool) { isTurnLocationOnLinkActive = new }
    
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
        networkChecker.connectionAvailable ? startSync.toggle() : (alert = InAppAlerts.noNetworkAlert())
    }
    
    func infoButtonTapped() {
        isInfoPresented = true
    }
    
    func searchAndFollowTapped() {
        isSearchAndFollow = true
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
        !userSettings.disableMapping && locationHandler.isLocationDenied() ? .location : .mobile
    }
}
