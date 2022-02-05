import Foundation

public final class WeakRef<T: AnyObject>: CustomStringConvertible {
    public weak var object: T?
    
    public init(_ object: T) {
        self.object = object
    }
    
    public var description: String {
        guard let object = object else {
            return "EmptyWeakRef[\(String(describing: T.self))]"
        }
        return "WeakRef[\(String(describing: object))]"
    }
}
