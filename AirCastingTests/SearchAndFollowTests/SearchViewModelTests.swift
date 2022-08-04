// Created by Lunar on 03/08/2022.
//
import XCTest
@testable import AirCasting

class SearchViewModelTests: XCTestCase {
    var sut: SearchViewModel!
    
    override func setUp() {
        super.setUp()
        sut = .init()
    }
    
    func test_onInitialization_onlyParticulateMatterShouldBeSelected() {
        let selected = sut.measurementTypes.filter({ $0.isSelected })
        XCTAssertEqual(selected.count, 1)
        XCTAssertEqual(selected.first?.name, "Particulate Matter")
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
    
    func test_whenAskedToDeselectAll_shouldIsSelectedBeFalse() {
        sut.sensorTypes = [.init(isSelected: true, name: "1"),
                           .init(isSelected: false, name: "2"),
                           .init(isSelected: true, name: "3")]
        
        sut.deselectAll(sut.sensorTypes)
        let unSelected = sut.sensorTypes.filter({ !$0.isSelected })
        XCTAssertEqual(unSelected.count, sut.sensorTypes.count)
    }
    
    func test_particulateMatterTap_correspondingSensorsShouldAppear() {
        let particulateMatter = "Particulate Matter"
        sut.onParameterTap(with: particulateMatter)
        XCTAssertEqual(sut.sensorTypes.count, 3)
    }
    
    func test_ozoneTap_correspondingSensorsShouldAppear() {
        let particulateMatter = "Ozone"
        sut.onParameterTap(with: particulateMatter)
        XCTAssertEqual(sut.sensorTypes.count, 1)
    }
}
