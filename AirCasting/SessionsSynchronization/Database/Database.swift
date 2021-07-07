import Foundation

// Temporary namespacing struct until we divide stuff into packages or frameworks
struct Database {
    private init() { }
}

extension Database {
    enum Constraint {
        case all
        case predicate(NSPredicate)
    }
}

// MARK: - Sessions handling

protocol SessionsFetchable {
    func fetchSessions(constrained: Database.Constraint, completion: @escaping (Result<[Database.Session], Error>) -> Void)
}

protocol SessionRemovable {
    func removeSessions(where: Database.Constraint, completion: ((Error?) -> Void)?)
}

protocol SessionInsertable {
    func insertSessions(_ sessions: [Database.Session], completion: ((Error?) -> Void)?)
}
