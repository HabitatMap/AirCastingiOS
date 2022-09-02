// Created by Lunar on 27/05/2021.
//

import Foundation
import FirebaseCrashlytics

public func assert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = String(), file: StaticString = #fileID, line: UInt = #line) {
    if !condition() {
        assertionFailure(message(), file: file, line: line)
    }
}

public func assertionFailure(_ message: @autoclosure () -> String = String(), file: StaticString = #fileID, line: UInt = #line) {
    Swift.assert(false, message(), file: file, line: line)
    #if !DEBUG
    let file = "\(file)".split(separator: "/").last.map(String.init) ?? "\(file)"
    Crashlytics.crashlytics().record(error: NSError(domain: "\(file)_\(line)", code: Int(line), userInfo: [NSLocalizedDescriptionKey: "Assertion failure: \(message()) file: \(file) line: \(line)"]))
    #endif
}
