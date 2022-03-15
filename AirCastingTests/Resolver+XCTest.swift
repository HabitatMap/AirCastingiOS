// Created by Lunar on 06/03/2022.
//

import XCTest
import Resolver
@testable import AirCasting

extension Resolver {
    
    static var test: Resolver!
    
    static func resetUnitTestRegistrations() {
        Resolver.test = Resolver(child: .main)
        Resolver.root = Resolver.test
    }
}

class ACTestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        Resolver.resetUnitTestRegistrations()
    }
    
    override func tearDown() {
        super.tearDown()
        Resolver.root = Resolver.main
    }
}
