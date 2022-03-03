import Foundation

extension WeakRef: DisposableDataHolder where T: DisposableDataHolder {
    var disposeQueue: DispatchQueue? { object?.disposeQueue }
    func dispose() throws { try object?.dispose() }
}
