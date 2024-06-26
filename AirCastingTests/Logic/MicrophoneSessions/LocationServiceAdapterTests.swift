// Created by Lunar on 26/07/2022.
//

import XCTest
import Combine
import CoreLocation
@testable import AirCasting

class LocationServiceAdapterTests: XCTestCase {
    
    func test_whenInitialized_startsLocationTracking() {
        let trackerSpy = TrackerSpy()
        let sut = LocationServiceAdapter(tracker: trackerSpy)
        XCTAssertEqual(trackerSpy.calls, [.start])
    }
    
    func test_whenReleased_stopsLocationTracking() {
        let trackerSpy = TrackerSpy()
        var sut: LocationServiceAdapter? = LocationServiceAdapter(tracker: trackerSpy)
        sut = nil
        XCTAssertNil(sut)
        XCTAssertEqual(trackerSpy.calls, [.start, .stop])
    }
    
    func test_wheGettingLocation_returnsValueProvidedByTracker() throws {
        let location = CLLocation.cracow
        let sut = LocationServiceAdapter(tracker: TrackerStub(withStubbedLocation: location))
        let returnedLocation = try XCTUnwrap(sut.getCurrentLocation())
        XCTAssertEqual(returnedLocation.latitude, location.coordinate.latitude, accuracy: 0.0001)
        XCTAssertEqual(returnedLocation.longitude, location.coordinate.longitude, accuracy: 0.0001)
    }
    
    // MARK: Test doubles
    
    class TrackerSpy: LocationTracker {
        func oneTimeLocationUpdate() async throws -> CLLocation {
            // Think about it - it was done without much thinking, just to make it run
            .cracow
        }
        
        enum HistoryItem: Equatable {
            case start, stop, getLocation
        }
        
        private(set) var calls: [HistoryItem] = []
        
        func start() {
            calls.append(.start)
        }
        
        func stop() {
            calls.append(.stop)
        }
        
        var location: CurrentValueSubject<CLLocation?, Never> {
            get { calls.append(.getLocation); return .init(nil) }
        }
    }
    
    class TrackerStub: LocationTracker {
        func oneTimeLocationUpdate() async throws -> CLLocation {
            // Think about it - it was done without much thinking, just to make it run
            .cracow
        }
        
        let location: CurrentValueSubject<CLLocation?, Never>

        func start() { }
        func stop() { }
        
        init(withStubbedLocation location: CLLocation?) {
            self.location = .init(location)
        }
    }
}
