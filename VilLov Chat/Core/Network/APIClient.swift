//
//  APIClient.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//
// This is our reusable HTTP client

import Foundation

final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenStore: AuthTokenStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        tokenStore: AuthTokenStore
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func get<Response: Decodable>(
        _ endpoint: Endpoint,
        authenticated: Bool = true
    ) async throws -> Response {
        let request = try makeRequest(
            endpoint: endpoint,
            method: "GET",
            body: nil,
            authenticated: authenticated
        )

        return try await perform(request)
    }

    func post<RequestBody: Encodable, Response: Decodable>(
        _ endpoint: Endpoint,
        body: RequestBody,
        authenticated: Bool = true
    ) async throws -> Response {
        let bodyData: Data
        do {
            bodyData = try encoder.encode(body)
        } catch {
            throw APIError.encodingFailed
        }

        let request = try makeRequest(
            endpoint: endpoint,
            method: "POST",
            body: bodyData,
            authenticated: authenticated
        )

        return try await perform(request)
    }

    func postEmpty<RequestBody: Encodable>(
        _ endpoint: Endpoint,
        body: RequestBody,
        authenticated: Bool = true
    ) async throws {
        let bodyData: Data
        do {
            bodyData = try encoder.encode(body)
        } catch {
            throw APIError.encodingFailed
        }

        let request = try makeRequest(
            endpoint: endpoint,
            method: "POST",
            body: bodyData,
            authenticated: authenticated
        )

        let (_, response) = try await session.data(for: request)
        try validate(response)
    }

    private func makeRequest(
        endpoint: Endpoint,
        method: String,
        body: Data?,
        authenticated: Bool
    ) throws -> URLRequest {
        guard let url = URL(string: endpoint.path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated, let accessToken = tokenStore.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        do {
            let (data, response) = try await session.data(for: request)
            try validate(response)

            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                let rawBody = String(data: data, encoding: .utf8) ?? "<non-utf8 response>"
                print("API decode failed")
                print("URL:", request.url?.absoluteString ?? "<unknown>")
                print("Expected type:", String(describing: Response.self))
                print("Raw response body:", rawBody)
                print("Underlying decode error:", error)
                throw APIError.decodingFailed
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(error)
        }
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}
