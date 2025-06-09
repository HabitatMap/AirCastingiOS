// Created by Lunar on 9.06.25.
//

import Foundation

func waitFor<T>(_ operation: @escaping () async throws -> T) throws -> T {
    guard !Thread.isMainThread else {
        fatalError("You should not block the main thread waiting for async code.")
    }
    var result: T!
    var caughtError: Error?

    let semaphore = DispatchSemaphore(value: 0)

    Task {
        do {
            result = try await operation()
        } catch {
            caughtError = error
        }
        semaphore.signal()
    }

    semaphore.wait()

    if let error = caughtError {
        throw error
    }
    return result
}
