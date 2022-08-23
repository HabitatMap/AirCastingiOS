import Foundation

protocol ConnectionProtectable {
    func isAirBeamAvailableForNewConnection(peripheraUUID: String, completion: @escaping (Result<Void, Error>) -> Void)
}
