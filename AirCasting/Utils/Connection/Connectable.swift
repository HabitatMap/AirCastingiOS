import Foundation

protocol Connectable {
    func isAvailableForNewConnection() -> Result<Void, Error>
}
