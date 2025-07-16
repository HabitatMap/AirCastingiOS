struct BatchError: Error {
    let errors: [Error]
    
    var localizedDescription: String {
        let failureCount = errors.count
        
        var description = "Batch operation completed with \(failureCount) failures"
        
        if !errors.isEmpty {
            description += "\n\nFailure details:"
            for (index, error) in errors.enumerated() {
                description += "\n\(index + 1). \(error.localizedDescription)"
            }
        }
        
        return description
    }
}
