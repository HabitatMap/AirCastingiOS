// Created by Lunar on 04/08/2021.
//

import XCTest
@testable import AirCasting
import CoreLocation

class ChooseSessionTypeTests: XCTestCase {

    private var defaultSessionTypeViewModel: ChooseSessionTypeViewModel!
    
    override func setUp() {
        defaultSessionTypeViewModel = ChooseSessionTypeViewModel(locationHandler: DefaultLocationHandler(locationTracker: LocationTracker(locationManager: CLLocationManager())), bluetoothHandler: DefaultBluetoothHandler(bluetoothManager: BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared)))), userSettings: UserSettings(), sessionContext: CreateSessionContext(), urlProvider: UserDefaultsBaseURLProvider())
    }
    
    func test_fixSessionNextStep() {
        if defaultSessionTypeViewModel.locationHandler.locationTracker.locationGranted == .denied {
            XCTAssertEqual(defaultSessionTypeViewModel.fixSessionNextStep(), .location)
        } else {
            XCTAssertNotNil(defaultSessionTypeViewModel.fixSessionNextStep())
        }
    }
    
    func test_mobileSessionNextStep() {
        if defaultSessionTypeViewModel.locationHandler.locationTracker.locationGranted == .denied {
            XCTAssertEqual(defaultSessionTypeViewModel.mobileSessionNextStep(), .location)
        } else {
            XCTAssertEqual(defaultSessionTypeViewModel.mobileSessionNextStep(), .mobile)
        }
    }
    
    func test_createdFixSessionIsFixed() {
        defaultSessionTypeViewModel.createNewSession(isSessionFixed: true)
        XCTAssertEqual(defaultSessionTypeViewModel.sessionContext.sessionType, .fixed)
        XCTAssertEqual(defaultSessionTypeViewModel.sessionContext.contribute, true)
    }
    
    func test_createdNotAFixSessionIsNotFixed() {
        defaultSessionTypeViewModel.createNewSession(isSessionFixed: false)
        XCTAssertEqual(defaultSessionTypeViewModel.sessionContext.sessionType, .mobile)
        XCTAssertEqual(defaultSessionTypeViewModel.sessionContext.contribute, defaultSessionTypeViewModel.userSettings.contributingToCrowdMap)
    }
}
