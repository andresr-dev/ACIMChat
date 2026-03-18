//
//  ChatTests.swift
//  Chat
//
//  Created by Andres Raigoza on 16/03/26.
//

import Testing
@testable import Chat
import ComposableArchitecture
import Foundation

@MainActor @Suite
struct ChatTests {
  
  @Test
  func basicChatFlow() async throws {
    let userMessage = Message(id: UUID(0), text: "Hello!", role: .user, date: Date(timeIntervalSince1970: 1234567890))
    let aiResponse = Message(id: UUID(1), text: "Hello there!", role: .ai, date: Date(timeIntervalSince1970: 1234567890))
    
    let store = TestStore(initialState: Chat.State()) {
      Chat()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
      $0.aiClient.sendMessage = { _ in aiResponse }
    }
    
    await store.send(\.binding.text, "Hello!") {
      $0.text = "Hello!"
    }
    await store.send(.sendMessageButtonPressed) {
      $0.text = ""
      $0.messages = [userMessage]
      $0.isTyping = true
    }
    await store.receive(\.aiResponse.success) {
      $0.isTyping = false
      $0.messages = [userMessage, aiResponse]
    }
  }
}
