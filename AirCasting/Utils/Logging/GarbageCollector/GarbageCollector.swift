import Foundation

// <☕️>
// https://www.reddit.com/r/ProgrammerHumor/comments/6v60sa/the_best_thing_about_java_is_the_garbage/
// </☕️>
/// A class that manages low-disk scenario by removing disposable data provided by the `DisposableDataHolder` instances.
class GarbageCollector {
    private var holders: [DisposableDataHolder] = []
    private var lowDataNotificationHandle: Any?
    
    init() {
        Log.info("Garbage collector initialized")
        lowDataNotificationHandle = NotificationCenter.default.addObserver(forName: .NSBundleResourceRequestLowDiskSpace, object: nil, queue: .current) { _ in
            Log.info("Low disk space notification received, starting garbage collection process")
            self.collectGarbage()
        }
    }
    
    /// Adds a `DisposableDataHolder` to the list. Please note that this list references objects strongly. If you register a class type here, use a `WeakRef` wrapper.
    func addHolder(_ holder: DisposableDataHolder) {
        Log.verbose("Added disposable data holder to garbage collection: \(printable(holder))")
        holders.append(holder)
    }
    
    private func collectGarbage() {
        for holder in holders {
            let queue = holder.disposeQueue ?? DispatchQueue.global(qos: .utility)
            queue.async {
                let holderType = self.printable(holder)
                Log.info("Disposing data from the \(holderType)")
                do { try holder.dispose() }
                catch { Log.warning("Couldn't dispose data from the \(holderType) with error: \(error)") }
                Log.info("Data disposal from the \(holderType) succeeded")
            }
        }
    }
    
    private func printable(_ holder: DisposableDataHolder) -> String {
        String(describing: type(of: holder))
    }
}
