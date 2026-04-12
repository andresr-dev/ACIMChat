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
  var speak: @Sendable (_ text: String, _ language: String) async throws -> Void
  var stop: @Sendable () async -> Void
}

extension SpeechClient: TestDependencyKey {
  static let previewValue = SpeechClient()
  static let testValue = SpeechClient()
}

extension DependencyValues {
  var speechClient: SpeechClient {
    get { self[SpeechClient.self] }
    set { self[SpeechClient.self] = newValue }
  }
}
