// Created by Lunar on 01/07/2021.
//

import Foundation

final class APIcalls {
    func forgotPassword(login: String, completion: @escaping (Int) -> Void) {
        let params = ["user": ["login": login]]

        var request = URLRequest(url: URL(string: "http://aircasting.org/users/password.json")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        var returnCode = 404
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { _, response, _ -> Void in

            guard let httpResponse = response as? HTTPURLResponse else {
                print("error: not a valid http response")
                return
            }
            switch httpResponse.statusCode {
            case 200, 201:
                returnCode = 201
                print("Success")
            default:
                print("POST request got response \(httpResponse.statusCode)")
            }
            completion(returnCode)
        })
        task.resume()
    }
}
