//
//  AIClient.swift
//  Chat
//
//  Created by Andres Raigoza on 16/03/26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
public struct AIClient: Sendable  {
  static let baseURL = "https://us-central1-acim-chat.cloudfunctions.net"
  static let encoder = JSONEncoder()
  static let session: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest  = 30
    config.timeoutIntervalForResource = 60
    return URLSession(configuration: config)
  }()
  
  var sendMessage: @Sendable (_ history: [ChatMessage]) -> AsyncThrowingStream<String, Swift.Error> = { _ in .finished() }
  var generateTitle: @Sendable (_ question: String, _ answer: String) async throws -> String = { _, _ in "" }
}

extension DependencyValues {
  public var aiClient: AIClient {
    get { self[AIClient.self] }
    set { self[AIClient.self] = newValue }
  }
}

extension AIClient: TestDependencyKey {
  public static let previewValue = AIClient(
    sendMessage: { _ in
      AsyncThrowingStream { continuation in
        Task { @MainActor in
          try await Task.sleep(for: .seconds(4))
          var finalText = """
              Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor \
              incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud \
              exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute \
              irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla \
              pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui \
              officia deserunt mollit anim id est laborum.
              """
          while !finalText.isEmpty {
            let word = finalText.prefix { $0 != " " }
            try await Task.sleep(for: .milliseconds(50))
            finalText.removeFirst(word.count)
            finalText = finalText.trimmingCharacters(in: .whitespaces)
            continuation.yield(word + " ")
          }
          continuation.finish()
        }
      }
    },
    generateTitle: { _, _ in
      "Chat Title"
    }
  )
  
  public static let testValue = mock(.success)
  
  public enum MockState { case success, failure, cancellation, urlCancellation }
  
  public static func mock(_ state: MockState) -> AIClient {
    switch state {
    case .success:
      return AIClient(
        sendMessage: { _ in
          AsyncThrowingStream { continuation in
            Task { @MainActor in
              continuation.yield("Hello")
              continuation.finish()
            }
          }
        },
        generateTitle: { _, _ in
          "Chat Title"
        }
      )
    case .failure:
      return AIClient(
        sendMessage: { _ in
          AsyncThrowingStream { continuation in
            Task { @MainActor in
              continuation.finish(throwing: Error.invalidResponse)
            }
          }
        },
        generateTitle: { _, _ in
          "Chat Title"
        }
      )
    case .cancellation:
      return AIClient(
        sendMessage: { _ in
          AsyncThrowingStream { continuation in
            Task { @MainActor in
              continuation.finish(throwing: CancellationError())
            }
          }
        },
        generateTitle: { _, _ in
          "Chat Title"
        }
      )
    case .urlCancellation:
      return AIClient(
        sendMessage: { _ in
          AsyncThrowingStream { continuation in
            Task { @MainActor in
              continuation.finish(throwing: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))
            }
          }
        },
        generateTitle: { _, _ in
          "Chat Title"
        }
      )
    }
  }
}
