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
            let url = URL(string: "\(baseURL)/askACIM")
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
              language: DeviceInfo.language,
              history: history.map(RequestChatMessage.init)
            )
            request.httpBody = try encoder.encode(body)
            let (stream, response) = try await session.bytes(for: request)
            
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
    }, generateTitle: { question, answer in
      guard let url = URL(string: "\(baseURL)/generateTitle") else {
        throw Error.invalidURL
      }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try encoder.encode([
        "firstQuestion": question,
        "firstAnswer": answer,
        "language": DeviceInfo.language
      ])
      
      let (data, response) = try await session.data(for: request)
      
      guard let http = response as? HTTPURLResponse else {
        throw Error.invalidResponse
      }
      guard (200...299).contains(http.statusCode) else {
        throw Error.serverError(http.statusCode)
      }
      guard
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let title = json["title"] as? String
      else {
        throw Error.decodingError(NSError(domain: "Missing title field", code: 0))
      }
      return title
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
