//
//  APIError.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case serverError(statusCode: Int)
    case decodingFailed
    case encodingFailed
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .unauthorized:
            return "You are not authorized."
        case .forbidden:
            return "Access is forbidden."
        case .notFound:
            return "The requested resource was not found."
        case .serverError(let statusCode):
            return "The server returned an error (\(statusCode))."
        case .decodingFailed:
            return "Failed to decode the server response."
        case .encodingFailed:
            return "Failed to encode the request."
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}