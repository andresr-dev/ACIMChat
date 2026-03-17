//
//  AIClient.swift
//  Chat
//
//  Created by Andres Raigoza on 16/03/26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
struct AIClient: Sendable {
  var sendMessage: @Sendable (String) async throws -> Message
}

extension DependencyValues {
  nonisolated var aiClient: AIClient {
    get { self[AIClient.self] }
    set { self[AIClient.self] = newValue }
  }
}

extension AIClient {
  nonisolated private struct Response: Decodable {
    let answer: String
    let passagesUsed: Int
  }
  
  nonisolated private struct Request: Codable {
    let question: String
    let language: String
    let history: [ChatMessage]
  }
  
  private struct ChatMessage: Codable {
    let role: String
    let content: String
  }
  
  enum Error: Swift.Error {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError(Swift.Error)
  }
}

extension AIClient: DependencyKey {
  static let liveValue = AIClient(
    sendMessage: { question in
      let url = URL(string: "https://us-central1-acim-chat.cloudfunctions.net/askACIM")
      guard let url else {
        throw Error.invalidURL
      }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      let body = Request(
        question: question,
        language: "en",
        history: []
      )
      request.httpBody = try JSONEncoder().encode(body)
      
      let (data, response) = try await URLSession.shared.data(for: request)
      
      guard let httpResponse = response as? HTTPURLResponse else {
        throw Error.invalidResponse
      }
      guard (200...299).contains(httpResponse.statusCode) else {
        throw Error.serverError(httpResponse.statusCode)
      }
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      do {
        let response = try decoder.decode(Response.self, from: data)
        return await Message(text: response.answer, role: .ai)
      } catch {
        throw Error.decodingError(error)
      }
    }
  )
}
