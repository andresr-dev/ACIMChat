//
//  SpeechClient.swift
//  Chat
//
//  Created by Andres Raigoza on 9/04/26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
struct SpeechClient {
  var speak: @Sendable (_ text: String) async throws -> Void
  var stop: @Sendable () async -> Void
}

extension SpeechClient: TestDependencyKey {
  static let previewValue = SpeechClient { text in
    try await Task.sleep(for: .seconds(2))
  } stop: { }

  static let testValue = SpeechClient(
    speak: { _ in },
    stop: { }
  )
}

extension DependencyValues {
  var speechClient: SpeechClient {
    get { self[SpeechClient.self] }
    set { self[SpeechClient.self] = newValue }
  }
}
