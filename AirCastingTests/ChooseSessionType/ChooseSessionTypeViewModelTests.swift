// Created by Lunar on 04/08/2021.
//

import XCTest
@testable import AirCasting
import CoreLocation

class ChooseSessionTypeViewModelTests: XCTestCase {

    private var defaultSessionTypeViewModel: ChooseSessionTypeViewModel!
    
    override func setUp() {
        defaultSessionTypeViewModel = ChooseSessionTypeViewModel(locationHandler: DefaultLocationHandler(locationTracker: LocationTracker(locationManager: CLLocationManager())), bluetoothHandler: DefaultBluetoothHandler(bluetoothManager: BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared)))), userSettings: UserSettings(), sessionContext: CreateSessionContext(), urlProvider: UserDefaultsBaseURLProvider())
    }
    
    func test_fixSessionNextStep() {
        if defaultSessionTypeViewModel.passLocationHandler.locationTracker.locationGranted == .denied {
            XCTAssertEqual(defaultSessionTypeViewModel.fixedSessionNextStep(), .location)
        } else {
            XCTAssertNotNil(defaultSessionTypeViewModel.fixedSessionNextStep())
        }
    }
    
    func test_mobileSessionNextStep() {
        if defaultSessionTypeViewModel.passLocationHandler.locationTracker.locationGranted == .denied {
            XCTAssertEqual(defaultSessionTypeViewModel.mobileSessionNextStep(), .location)
        } else {
            XCTAssertEqual(defaultSessionTypeViewModel.mobileSessionNextStep(), .mobile)
        }
    }
    
    func test_createdFixSessionIsFixed() {
        defaultSessionTypeViewModel.createNewSession(isSessionFixed: true)
        XCTAssertEqual(defaultSessionTypeViewModel.passSessionContext.sessionType, .fixed)
        XCTAssertEqual(defaultSessionTypeViewModel.passSessionContext.contribute, true)
    }
    
    func test_createdNotAFixSessionIsNotFixed() {
        defaultSessionTypeViewModel.createNewSession(isSessionFixed: false)
        XCTAssertEqual(defaultSessionTypeViewModel.passSessionContext.sessionType, .mobile)
        XCTAssertEqual(defaultSessionTypeViewModel.passSessionContext.contribute, defaultSessionTypeViewModel.passUserSettings.contributingToCrowdMap)
    }
}
