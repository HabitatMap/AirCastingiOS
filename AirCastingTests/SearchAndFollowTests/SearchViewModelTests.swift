// Created by Lunar on 03/08/2022.
//
import XCTest
@testable import AirCasting

class SearchViewModelTests: XCTestCase {
    let sut: SearchViewModel = .init()
    
    func test_onInitialization_onlyParticulateMatterShouldBeSelected() throws {
        let selected = sut.measurementTypes.filter({ $0.isSelected })
        XCTAssertEqual(selected.count, 1)
        let name = try XCTUnwrap(selected.first?.name, "Problem occured when trying to get a name.")
        XCTAssertEqual(name, "Particulate Matter")
    }
    
    func test_whenSensorTapHappens_shouldSelectTapped() {
        sut.sensorTypes = [.init(isSelected: false, name: "1"),
                           .init(isSelected: true, name: "2"),
                           .init(isSelected: false, name: "3")]
        
        let tappingSensorName = "1"
        
        sut.onSensorTap(with: tappingSensorName)
        
        let selected = sut.sensorTypes.filter({ $0.isSelected })
        
        XCTAssertEqual(selected.count, 1)
        XCTAssertEqual(selected.first!.name, tappingSensorName)
    }
    
    func test_particulareMatterTapped_correspondingSensorsAppears() {
        let particulateMatter = "Particulate Matter"
        sut.onParameterTap(with: particulateMatter)
        XCTAssertEqual(sut.sensorTypes.map(\.name), ["AirBeam", "OpenAQ", "PurpleAir"])
    }
    
    func test_ozoneTapped_correspondingSensorsAppears() {
        let particulateMatter = "Ozone"
        sut.onParameterTap(with: particulateMatter)
        XCTAssertEqual(sut.sensorTypes.map(\.name), ["OpenAQ"])
    }
}
