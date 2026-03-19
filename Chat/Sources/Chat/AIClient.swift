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
  var sendMessage: @Sendable ([Message]) async throws -> Message
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
    let history: [ChatMessage]
  }
  
  struct ChatMessage: Encodable {
    let role: String
    let content: String
    
    init(message: Message) {
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
      let body = try getRequestFrom(messages: messages)
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
        return Message(text: response.answer, role: .ai)
      } catch {
        throw Error.decodingError(error)
      }
    }
  )
  
  static let previewValue = AIClient { question in
    try await Task.sleep(for: .seconds(2))
    return Message(text: "I don't know, try asking me something else.", role: .ai)
  }
  
  static let testValue = AIClient()
}

extension AIClient {
  static func getRequestFrom(messages: [Message]) throws -> Request {
    guard let question = messages.last?.text else {
      throw Error.invalidQuestion
    }
    var history = Array(messages.map(ChatMessage.init).dropLast())
    let maxHistorySize = 10
    if history.count > maxHistorySize {
      let messagesToRemove = history.count - maxHistorySize
      history.removeFirst(messagesToRemove)
    }
    return Request(
      question: question,
      language: "en",
      history: history
    )
  }
}
