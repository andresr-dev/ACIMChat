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
  var sendMessage: @Sendable (_ history: [ChatMessage]) -> AsyncThrowingStream<String, Swift.Error> = { _ in .finished() }
}

extension DependencyValues {
  public var aiClient: AIClient {
    get { self[AIClient.self] }
    set { self[AIClient.self] = newValue }
  }
}

extension AIClient: TestDependencyKey {
  public static let previewValue = AIClient { _ in
    AsyncThrowingStream { continuation in
      Task { @MainActor in
        try await Task.sleep(for: .seconds(2))
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
  }
  
  public static let testValue = mock(.success)
  
  public enum MockState { case success, failure, cancellation, urlCancellation }
  
  public static func mock(_ state: MockState) -> AIClient {
    switch state {
    case .success:
      return AIClient { _ in
        AsyncThrowingStream { continuation in
          Task { @MainActor in
            continuation.yield("Hello")
          }
        }
      }
    case .failure:
      return AIClient { _ in
        AsyncThrowingStream { continuation in
          Task { @MainActor in
            continuation.finish(throwing: Error.invalidResponse)
          }
        }
      }
    case .cancellation:
      return AIClient { _ in
        AsyncThrowingStream { continuation in
          Task { @MainActor in
            continuation.finish(throwing: CancellationError())
          }
        }
      }
    case .urlCancellation:
      return AIClient { _ in
        AsyncThrowingStream { continuation in
          Task { @MainActor in
            continuation.finish(throwing: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))
          }
        }
      }
    }
  }
}
