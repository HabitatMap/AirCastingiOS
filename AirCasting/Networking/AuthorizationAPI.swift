//
//  AuthorizationAPI.swift
//  AirCasting
//
//  Created by Lunar on 23/02/2021.
//

import Foundation
import Combine

class AuthorizationAPI {
    
    
    struct SignupAPIInput: Codable {
        let user: SignupUserInput
    }

    struct SignupUserInput: Codable {
        let email: String
        let username: String
        let password: String
        let send_emails: Bool
    }
    
    struct SignupAPIOutput: Codable {
        let id: Int
        let authentication_token: String
    }
    
    struct SigninUserInput: Codable {
        let username: String
        let password: String
    }
    
    struct SigninUserOutput: Codable {
        let authentication_token: String
    }
    
    
    static func createAccount(input: SignupAPIInput) -> AnyPublisher<SignupAPIOutput, Error> {
        let url = URL(string: "http://aircasting.org/api/user.json")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields?["Content-Type"] = "application/json"
        let encoder = JSONEncoder()
        let data = try? encoder.encode(input)
        request.httpBody = data
                
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data, response) in
                let decoder = JSONDecoder()
                let userOutput = try decoder.decode(SignupAPIOutput.self, from: data)
                return userOutput
            }
            .eraseToAnyPublisher()
    }
    
    static func signIn(input: SigninUserInput) -> AnyPublisher<SigninUserOutput, Error> {
        let url = URL(string: "http://aircasting.org/api/user.json")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields?["Content-Type"] = "application/json"
        let userinput = "\(input.username):\(input.password)"
        let base64input = userinput.data(using: .utf8)?.base64EncodedString() ?? ""
        request.allHTTPHeaderFields?["Authorization"] = "Basic \(base64input)"
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data, response) in
                let decoder = JSONDecoder()
                let userOutput = try decoder.decode(SigninUserOutput.self, from: data)
                return userOutput
            }
            .eraseToAnyPublisher()
    }
    
}
