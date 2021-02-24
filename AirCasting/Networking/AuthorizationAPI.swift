//
//  AuthorizationAPI.swift
//  AirCasting
//
//  Created by Lunar on 23/02/2021.
//

import Foundation
import Combine

class AuthorizationAPI {
    
    
    struct CreateAccountInput: Codable {
        let user: UserInput
    }

    struct UserInput: Codable {
        let email: String
        let username: String
        let password: String
        let send_emails: Bool
    }
    
    struct CreateAccountOutput: Codable {
        let id: Int
        let authentication_token: String
    }
    
    static func createAccount(input: CreateAccountInput) -> AnyPublisher<CreateAccountOutput, Error> {
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
                let userOutput = try decoder.decode(CreateAccountOutput.self, from: data)
                return userOutput
            }
            .eraseToAnyPublisher()
    }
    
}
