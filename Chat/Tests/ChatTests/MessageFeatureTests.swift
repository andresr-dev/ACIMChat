//
//  MessageFeatureTests.swift
//  Chat
//
//  Created by Andres Raigoza on 20/04/26.
//

import Testing
@testable import Chat
import ComposableArchitecture
import Foundation

@MainActor
struct MessageFeatureTests {
  
  @Test func basics() async {
    let store = TestStore(
      initialState: MessageFeature.State(message: .mockAIMessage)
    ) {
      MessageFeature()
    }
    
    await store.send(.speakButtonPressed) {
      $0.isSpeaking = true
    }
    await store.receive(\.delegate.stopOtherSpeakers)
    await store.receive(\.didStopSpeaking) {
      $0.isSpeaking = false
    }
  }
}
