// Created by Lunar on 16/08/2022.
//

import XCTest
import Resolver
@testable import AirCasting

class CalibratableMicrophoneDecoratorTests: ACTestCase {
    private let microphone = MicrophoneMock()
    private let calibrationValueProvider = MicrophoneCalibraionValueProviderStub()
    
    override func setUp() {
        super.setUp()
        Resolver.test.register { self.calibrationValueProvider as MicrophoneCalibraionValueProvider }
    }
    
    // MARK: Adjustment application tests
    
    func test_whenAskedForDecibelLevel_addsCorectValueToOriginalMeasurement() throws {
        let sut = createSUT(calibration: 333.0)
        microphone.stubbedLevel = 87.0
        let adjustment = sut.constAdjustment
        XCTAssertEqual(try XCTUnwrap(sut.getCurrentDecibelLevel()), 246 + adjustment, accuracy: 0.001)
    }
    
    // MARK: Message passing tests
    
    func test_startRecording_isPassedToWrappedMicrophone() throws {
        let sut = createSUT()
        try sut.startRecording()
        XCTAssertEqual(microphone.callHistory, [.start])
    }
    
    func test_stopRecording_isPassedToWrappedMicrophone() throws {
        let sut = createSUT()
        try sut.stopRecording()
        XCTAssertEqual(microphone.callHistory, [.stop])
    }
    
    func test_gettingPowerLevel_isPassedToWrappedMicrophone() throws {
        let sut = createSUT()
        _ = sut.getCurrentDecibelLevel()
        XCTAssertEqual(microphone.callHistory, [.getLevel])
    }
    
    // MARK: Helpers
    
    private func createSUT(calibration: Double? = nil) -> CalibratableMicrophoneDecorator {
        if let calibration = calibration {
            calibrationValueProvider.zeroLevelAdjustment = calibration
        }
        return CalibratableMicrophoneDecorator(microphone: microphone)
    }
    
    // MARK: Test doubles
    
    class MicrophoneCalibraionValueProviderStub: MicrophoneCalibraionValueProvider {
        var zeroLevelAdjustment: Double = 0.0
    }
}
