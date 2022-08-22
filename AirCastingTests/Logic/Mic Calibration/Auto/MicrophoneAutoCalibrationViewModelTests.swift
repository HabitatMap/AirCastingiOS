// Created by Lunar on 17/08/2022.
//

import XCTest
import Resolver
@testable import AirCasting

class MicrophoneAutoCalibrationViewModelTests: ACTestCase {
    private let dataStore = DataStore()
    
    override func setUp() {
        super.setUp()
        Resolver.test.register { self.dataStore }
            .implements(MicrophoneCalibrationValueWritable.self)
    }
    
    func test_whenInitialized_startsWithIdleState() {
        let sut = createSUT()
        XCTAssertEqual(sut.state, .idle)
    }
    
    func test_whenInitialized_noAlertIsShown() {
        let sut = createSUT()
        XCTAssertNil(sut.alert)
    }
    
    func test_calibrateTapped_changesStateToCalibrating() {
        let (sut, _) = createSUT(calibrator: InfiniteCalibrator())
        sut.calibrateTapped()
        XCTAssertEqual(sut.state, .calibrating)
    }
    
    func test_calibrateTapped_butCalibratorUnavailable_doesntStartCalibrating() {
        let (sut, calibratorSpy) = createSUT(calibrator: CalibratorSpy())
        calibratorSpy.isAvailable = false
        sut.calibrateTapped()
        XCTAssertEqual(calibratorSpy.startCalibrationCalledTimes, 0)
    }
    
    func test_calibrateTapped_butCalibratorUnavailable_staysIdle() {
        let (sut, calibratorDummy) = createSUT(calibrator: CalibratorDummy())
        calibratorDummy.isAvailable = false
        sut.calibrateTapped()
        XCTAssertEqual(sut.state, .idle)
    }
    
    func test_calibrateTapped_butCalibratorUnavailable_presentsAlert() {
        let (sut, calibratorDummy) = createSUT(calibrator: CalibratorDummy())
        calibratorDummy.isAvailable = false
        sut.calibrateTapped()
        XCTAssertEqual(sut.alert, InAppAlerts.microphoneUnavailableForCalibration())
    }
    
    func test_calibrateTapped_andNoMicrophonePermissions_requestsPermissions() {
        let (sut, permissionsSpy) = createSUT(permissions: PermissionsSpy())
        permissionsSpy.permissionGranted = false
        sut.calibrateTapped()
        XCTAssertEqual(permissionsSpy.requestRecordPermissionCalledTimes, 1)
    }
    
    func test_requestingMicPermissions_userGrantsPermission_startsCalibration() {
        let (sut, calibratorSpy, permissionsStub) = createSUT(calibrator: CalibratorSpy(), permissions: PermissionsStub())
        permissionsStub.permissionGranted = false
        permissionsStub.shouldGrantPermission = true
        sut.calibrateTapped()
        XCTAssertEqual(calibratorSpy.startCalibrationCalledTimes, 1)
    }
    
    func test_requestingMicPermissions_userDeniesPermission_doesntStartCalibration() {
        let (sut, calibratorSpy, permissionsStub) = createSUT(calibrator: CalibratorSpy(), permissions: PermissionsStub())
        permissionsStub.permissionGranted = false
        permissionsStub.shouldGrantPermission = false
        sut.calibrateTapped()
        XCTAssertEqual(calibratorSpy.startCalibrationCalledTimes, 0)
    }
    
    func test_requestingMicPermissions_userDeniesPermission_staysIdle() {
        let (sut, permissionsStub) = createSUT(permissions: PermissionsStub())
        permissionsStub.permissionGranted = false
        permissionsStub.shouldGrantPermission = false
        sut.calibrateTapped()
        XCTAssertEqual(sut.state, .idle)
    }
    
    func test_calibrationFinishes_withSuccess_changesStateToDone() {
        let (sut, calibratorStub) = createSUT(calibrator: CalibratorStub())
        calibratorStub.toReturn = .success(.any)
        sut.calibrateTapped()
        XCTAssertEqual(sut.state, .done)
    }
    
    func test_calibrationFinishes_withSuccess_savesRecordedValueToStoreWithAddedPadding() {
        let (sut, calibratorStub) = createSUT(calibrator: CalibratorStub())
        let lowestPowerRecorded = 42.0
        calibratorStub.toReturn = .success(.init(lowestPower: lowestPowerRecorded, highestPower: .infinity))
        sut.calibrateTapped()
        XCTAssertEqual(dataStore.zeroLevelAdjustment, lowestPowerRecorded + MicrophoneCalibrationConstants.automaticCalibrationPadding)
    }
    
    func test_calibrationFinishes_withSuccess_noAlertIsPresented() {
        let (sut, calibratorStub) = createSUT(calibrator: CalibratorStub())
        calibratorStub.toReturn = .success(.any)
        sut.calibrateTapped()
        XCTAssertNil(sut.alert)
    }
    
    func test_calibrationFinishes_withFailure_changesStateToIdle() {
        let (sut, calibratorStub) = createSUT(calibrator: CalibratorStub())
        calibratorStub.toReturn = .failure(.any)
        sut.calibrateTapped()
        XCTAssertEqual(sut.state, .idle)
    }
    
    func test_calibrationFinishes_withFailure_presentsAlert() {
        let (sut, calibratorStub) = createSUT(calibrator: CalibratorStub())
        let errorToReturn = DummyError()
        calibratorStub.toReturn = .failure(.microphoneError(errorToReturn))
        sut.calibrateTapped()
        XCTAssertEqual(sut.alert,
                       InAppAlerts.microphoneCalibrationError(error: MicrophoneCalibrationError.microphoneError(errorToReturn)))
    }
    
    // MARK: Helpers
    
    private func createSUT() -> MicrophoneAutoCalibrationViewModel {
        let (sut, _, _) = createSUT(calibrator: CalibratorDummy(), permissions: PermissionsDummy())
        return sut
    }
    
    private func createSUT<P: MicrophonePermissions>(permissions: P) -> (MicrophoneAutoCalibrationViewModel, P) {
        let (sut, _, permissions) = createSUT(calibrator: CalibratorDummy(), permissions: permissions)
        return (sut, permissions)
    }
    
    private func createSUT<C: MicrophoneCalibration>(calibrator: C) -> (MicrophoneAutoCalibrationViewModel, C) {
        let (sut, calibrator, _) = createSUT(calibrator: calibrator, permissions: PermissionsDummy())
        return (sut, calibrator)
    }
    
    private func createSUT<C: MicrophoneCalibration, P: MicrophonePermissions>(calibrator: C, permissions: P) -> (MicrophoneAutoCalibrationViewModel, C, P) {
        Resolver.test.register { calibrator as MicrophoneCalibration }
        Resolver.test.register { permissions as MicrophonePermissions }
        return (MicrophoneAutoCalibrationViewModel(), calibrator, permissions)
    }
    
    // MARK: Test doubles
    
    private class DataStore: MicrophoneCalibrationValueWritable {
        var zeroLevelAdjustment: Double = 0.0
    }
    
    private class CalibratorDummy: MicrophoneCalibration {
        var isAvailable: Bool = true
        func startCalibration(completion: @escaping (Result<MicrophoneCalibrationDescription, MicrophoneCalibrationError>) -> ()) {
            completion(.success(.init(lowestPower: 0, highestPower: 0)))
        }
    }
    
    private class CalibratorStub: MicrophoneCalibration {
        var isAvailable: Bool = true
        
        var toReturn: Result<MicrophoneCalibrationDescription, MicrophoneCalibrationError> = .success(.init(lowestPower: 0, highestPower: 0))
        
        func startCalibration(completion: @escaping (Result<MicrophoneCalibrationDescription, MicrophoneCalibrationError>) -> ()) {
            completion(toReturn)
        }
    }
    
    private class CalibratorSpy: MicrophoneCalibration {
        var isAvailable: Bool = true
        
        var startCalibrationCalledTimes = 0
        
        func startCalibration(completion: @escaping (Result<MicrophoneCalibrationDescription, MicrophoneCalibrationError>) -> ()) {
            startCalibrationCalledTimes += 1
        }
    }
    
    private class InfiniteCalibrator: MicrophoneCalibration {
        private(set) var isAvailable: Bool = true
        func startCalibration(completion: @escaping (Result<MicrophoneCalibrationDescription, MicrophoneCalibrationError>) -> ()) { }
    }
    
    private class PermissionsDummy: MicrophonePermissions {
        let permissionGranted: Bool = true
        func requestRecordPermission(_ response: @escaping (Bool) -> Void) { response(true) }
    }
    
    private class PermissionsSpy: MicrophonePermissions {
        var permissionGranted: Bool = true
        
        var requestRecordPermissionCalledTimes = 0
        
        func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
            requestRecordPermissionCalledTimes += 1
        }
    }
    
    private class PermissionsStub: MicrophonePermissions {
        var permissionGranted: Bool = true
        
        var shouldGrantPermission = true
        
        func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
            permissionGranted = shouldGrantPermission
            response(shouldGrantPermission)
        }
    }
}

fileprivate extension MicrophoneCalibrationDescription {
    static var any: Self { .init(lowestPower: 0, highestPower: 0) }
}

fileprivate extension MicrophoneCalibrationError {
    static var any: Self { .couldntGetEnoughMeasurements }
}
