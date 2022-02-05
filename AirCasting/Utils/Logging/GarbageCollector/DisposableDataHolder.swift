import Foundation

protocol DisposableDataHolder {
    /// The queue to run dispose method on. Will be executed on arbitrary thread if `nil`.
    var disposeQueue: DispatchQueue? { get }
    /// This func will be triggered in order to dispose of unneeded data
    func dispose() throws
}

extension DisposableDataHolder {
    var disposeQueue: DispatchQueue? { nil }
}
