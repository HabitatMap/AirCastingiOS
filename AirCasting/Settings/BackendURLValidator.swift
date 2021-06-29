//
//  BackendURLValidator.swift
//  URLValidation
//
// Created by Lunar on 25/06/2021.
//

import Foundation

class BackendURLBuilder {
    enum ValidationError: Error {
        case invalidURL
        case invalidPort
        case noURL
    }
    
    func createURL(url: String, port: String) throws -> URL? {
        if url.count == 0 && port.count == 0 { return nil }
        if url.count == 0 && port.count > 0 { throw ValidationError.noURL }
        let url = appendURLWithSchemeIfNotPresent(url: url)
        var components = try getComponents(url: url)
        try validateHost(for: components)
        components.port = try getPortNumber(from: port)
        return components.url!
    }
    
    private func getComponents(url: String) throws -> URLComponents {
        guard let components = URLComponents(string: url) else {
            throw ValidationError.invalidURL
        }
        return components
    }
    
    private func validateHost(for components: URLComponents) throws {
        let host = try getHost(from: components).components(separatedBy: ".")
        guard host.count > 1, host.allSatisfy({ $0.count > 0 }) else {
            throw ValidationError.invalidURL
        }
    }
    
    private func getHost(from components: URLComponents) throws -> String {
        guard let host = components.host else {
            throw ValidationError.invalidURL
        }
        return host
    }
    
    private func getPortNumber(from port: String) throws -> Int? {
        if port.count == 0 { return nil }
        guard let portNumber = Int(port) else {
            throw ValidationError.invalidPort
        }
        return portNumber
    }
    
    private func appendURLWithSchemeIfNotPresent(url: String) -> String {
        var newUrl = url
        if !url.hasPrefix("http") {
            newUrl = "http://"+url
        }
        return newUrl
    }
}
