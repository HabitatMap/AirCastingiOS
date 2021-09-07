// Created by Lunar on 06/07/2021.
//

@testable import AirCasting

/// A test-wide global persistence object. This is used because we cannot load model more than once, can be fixed in the future by using some statics if desired
let persistence = PersistenceController(inMemory: true)
