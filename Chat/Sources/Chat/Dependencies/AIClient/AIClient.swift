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
        continuation.yield(
//          ChatMessage(id: UUID(), text: "Hello there!", role: .ai, date: .now)
          "Hello"
        )
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
