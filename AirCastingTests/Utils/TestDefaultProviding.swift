// Created by Lunar on 14/06/2021.
//

import Foundation

protocol TestDefaultProviding {
    static var `default`: Self { get }
}

extension String: TestDefaultProviding {
    static var `default`: String { "Lorem ipsum" }
}

extension Bool: TestDefaultProviding {
    static var `default`: Bool { false }
}

extension Double: TestDefaultProviding {
    static var `default`: Double { 4.44 }
}

extension Int: TestDefaultProviding {
    static var `default`: Int { 42 }
}

extension URL: TestDefaultProviding {
    static var `default`: URL { URL(string: "https://www.google.com/")!  }
}

extension Optional: TestDefaultProviding where Wrapped: TestDefaultProviding {
    static var `default`: Optional<Wrapped> { Wrapped.default }
}

extension Array: TestDefaultProviding where Element: TestDefaultProviding {
    static var `default`: Array<Element> { .init(repeating: Element.default, count: 5) }
}

extension Dictionary: TestDefaultProviding where Key: TestDefaultProviding, Value: TestDefaultProviding {
    static var `default`: Dictionary<Key, Value> { [Key.default : Value.default] }
}
