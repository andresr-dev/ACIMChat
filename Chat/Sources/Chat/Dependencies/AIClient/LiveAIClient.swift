//
//  LiveAIClient.swift
//  Chat
//
//  Created by Andres Raigoza on 9/04/26.
//

import Dependencies
import Foundation

extension AIClient: DependencyKey {
  public static let liveValue = AIClient(
    sendMessage: { history in
      AsyncThrowingStream { continuation in
        Task {
          do {
            let url = URL(string: "https://us-central1-acim-chat.cloudfunctions.net/askACIM")
            guard let url else {
              continuation.finish(throwing: Error.invalidURL)
              return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            guard let question = history.last?.text else {
              continuation.finish(throwing: Error.invalidQuestion)
              return
            }
            let body = Request(
              question: question,
              language: "es",
              history: history.map(RequestChatMessage.init)
            )
            request.httpBody = try JSONEncoder().encode(body)
            let (stream, response) = try await URLSession.shared.bytes(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
              continuation.finish(throwing: Error.invalidResponse)
              return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
              continuation.finish(throwing: Error.serverError(httpResponse.statusCode))
              return
            }
            for try await line in stream.lines {
              guard line.hasPrefix("data: ") else { continue }
              let jsonString = String(line.dropFirst(6))

              guard let data = jsonString.data(using: .utf8),
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
              else { continue }

              if let token = json["token"] as? String {
                continuation.yield(token)
              }
              if json["done"] as? Bool == true {
                continuation.finish()
              }
            }
          } catch {
            continuation.finish(throwing: error)
          }
        }
      }
    }
  )
  
  private struct Response: Decodable {
    let answer: String
    let passagesUsed: Int
  }
  
  private struct Request: Encodable {
    let question: String
    let language: String
    let history: [RequestChatMessage]
  }
  
  private struct RequestChatMessage: Encodable {
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
