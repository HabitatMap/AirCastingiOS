//
//  AuthorizationAPI.swift
//  AirCasting
//
//  Created by Lunar on 23/02/2021.
//

import Foundation

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
    ///api/user

    var currentTask: Any?
    
    func blaablabla(input: CreateAccountInput) {
        if let url = URL(string: "https://google.pl") {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let encoder = JSONEncoder()
            let data = try? encoder.encode(input)
            //request.httpBody = data
            
            currentTask = URLSession.shared.dataTaskPublisher(for: request)
                .sink { (completion) in
                    switch completion {
                    case .finished:
                        print("Success")
                    case .failure(let error):
                        print("ERROR: \(error)")
                    }
                } receiveValue: { (data, response) in
                    let dataStr = String(data: data, encoding: .utf8)
                    print(dataStr ?? "")
                }

        }
    }
    
    
    
}
