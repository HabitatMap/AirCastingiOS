import Foundation

class SignInPersistance: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var email: String = ""
    @Published var signInActive: Bool = false
    
    public static let shared = SignInPersistance()
    
    func clearCredentials() {
        username = ""
        email = ""
        password = ""
    }

    func clearDataWithCredentials() {
        username = ""
        email = ""
        password = ""
        signInActive = false
    }
}
