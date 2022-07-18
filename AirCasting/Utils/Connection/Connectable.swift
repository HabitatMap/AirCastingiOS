import Foundation

protocol Connectable {
    func isAirBeamAvailableForNewConnection() -> Result<Void, Error>
}
