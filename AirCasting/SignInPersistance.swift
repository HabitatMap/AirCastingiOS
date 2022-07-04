import Foundation

class SignInPersistance: ObservableObject {
    enum ScreenState {
        case signIn
        case createAccount
    }
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var email: String = ""
    @Published var credentialsScreen: ScreenState = .createAccount
    
    public static let shared = SignInPersistance()
    
    func clearCredentials() {
        username = ""
        email = ""
        password = ""
    }

    func clearSavedStatesWithCredentials() {
        username = ""
        email = ""
        password = ""
        credentialsScreen = .createAccount
    }
}
