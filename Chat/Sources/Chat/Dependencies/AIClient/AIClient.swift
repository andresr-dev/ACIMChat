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
  var sendMessage: @Sendable ([ChatMessage]) async throws -> ChatMessage
}

extension DependencyValues {
  public var aiClient: AIClient {
    get { self[AIClient.self] }
    set { self[AIClient.self] = newValue }
  }
}

extension AIClient: TestDependencyKey {
  public static let previewValue = AIClient { _ in
    try await Task.sleep(for: .seconds(2))
    return ChatMessage(id: UUID(), text: "Hello there!", role: .ai, date: .now)
  }
  
  public static let testValue = mock(.success)
  
  public enum MockState { case success, failure, cancellation, urlCancellation }
  
  public static func mock(_ state: MockState) -> AIClient {
    switch state {
    case .success:
      return AIClient { _ in .mockAIMessage
      }
    case .failure:
      return AIClient { _ in throw Error.invalidResponse }
    case .cancellation:
      return AIClient { _ in throw CancellationError() }
    case .urlCancellation:
      return AIClient { _ in throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled) }
    }
  }
}
