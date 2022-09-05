// Created by Lunar on 17/08/2022.
//

import XCTest
import Resolver
@testable import AirCasting

class MicrophoneManualCalibrationViewModelTests: ACTestCase {
    private let dataStore = DataStore()
    
    override func setUp() {
        super.setUp()
        Resolver.test.register { self.dataStore }
            .implements(MicrophoneCalibrationValueWritable.self)
            .implements(MicrophoneCalibraionValueProvider.self)
    }
    
    func test_initializesText_withPreexistingValue() {
        dataStore.zeroLevelAdjustment = 42.0
        let sut = createSUT()
        XCTAssertEqual(sut.text, "42")
    }
    
    func test_whenInputReceived_doesntUpdateDataStore() {
        let storedValue = 42.0
        dataStore.zeroLevelAdjustment = storedValue
        let sut = createSUT()
        sut.text = "50"
        XCTAssertEqual(dataStore.zeroLevelAdjustment, storedValue)
    }
    
    func test_inputIsValid_enablesOkButton() {
        let sut = createSUT()
        sut.text = "51"
        XCTAssertEqual(sut.okButtonEnabled, true)
    }
    
    func test_inputIsInvalid_disablesOkButton() {
        let sut = createSUT()
        sut.text = "KANYE WEST"
        XCTAssertEqual(sut.okButtonEnabled, false)
    }
    
    func test_okTapped_callsExitRoute() {
        var exitCalledTimes = 0
        let sut = createSUT(exitRoute: { exitCalledTimes += 1 })
        sut.okTapped()
        XCTAssertEqual(exitCalledTimes, 1)
    }
    
    func test_okTapped_updatesStorageWithNewValue() {
        let initialStoreValue = 42.0
        let updatedValue = 50.0
        dataStore.zeroLevelAdjustment = initialStoreValue
        let sut = createSUT()
        sut.text = "\(Int(updatedValue))"
        sut.okTapped()
        XCTAssertEqual(dataStore.zeroLevelAdjustment, updatedValue)
    }
    
    func test_cancelTapped_callsExitRoute() {
        var exitCalledTimes = 0
        let sut = createSUT(exitRoute: { exitCalledTimes += 1 })
        sut.cancelTapped()
        XCTAssertEqual(exitCalledTimes, 1)
    }
    
    // MARK: Helpers
    
    private func createSUT(exitRoute: (() -> Void)? = nil) -> MicrophoneManualCalibrationViewModel {
        MicrophoneManualCalibrationViewModel(exitRoute: exitRoute ?? { })
    }
    
    // MARK: Test doubles
    
    private class DataStore: MicrophoneCalibrationValueWritable, MicrophoneCalibraionValueProvider {
        var zeroLevelAdjustment: Double = 0.0
    }
}
