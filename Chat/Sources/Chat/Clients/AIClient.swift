//
//  AIClient.swift
//  Chat
//
//  Created by Andres Raigoza on 16/03/26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
struct AIClient {
  var sendMessage: @Sendable ([ChatMessage]) async throws -> ChatMessage
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
  
  nonisolated struct Request: Encodable {
    let question: String
    let language: String
    let history: [RequestChatMessage]
  }
  
  struct RequestChatMessage: Encodable {
    let role: String
    let content: String
    
    init(message: ChatMessage) {
      self.role = message.role.rawValue
      self.content = message.text
    }
  }
  
  enum Error: Swift.Error {
    case invalidURL
    case invalidResponse
    case invalidQuestion
    case serverError(Int)
    case decodingError(Swift.Error)
  }
}

extension AIClient: DependencyKey {
  static let liveValue = AIClient(
    sendMessage: { messages in
      let url = URL(string: "https://us-central1-acim-chat.cloudfunctions.net/askACIM")
      guard let url else {
        throw Error.invalidURL
      }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      guard let question = messages.last?.text else {
        throw Error.invalidQuestion
      }
      let history = messages.map(RequestChatMessage.init)
      
      let body = Request(
        question: question,
        language: "es",
        history: history
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
        return ChatMessage(text: response.answer, role: .ai)
      } catch {
        throw Error.decodingError(error)
      }
    }
  )
}

extension AIClient {
  static let previewValue = AIClient { question in
    try await Task.sleep(for: .seconds(1))
    return ChatMessage(id: UUID(), text: "Hello there!", role: .ai, date: .now)
  }
  
  static let testValue = AIClient()
  
  enum MockState { case success, failure }
  
  static func mock(_ state: MockState) -> AIClient {
    switch state {
    case .success:
      return AIClient { _ in .mockAIMessage }
    case .failure:
      return AIClient { _ in throw Error.invalidResponse }
    }
  }
}
