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

@MainActor
struct ChatTests {
  let date = Date(timeIntervalSince1970: 1234567890)
  var aiResponse: ChatMessage {
    ChatMessage(id: UUID(1), text: "Hello there!", role: .ai, date: date)
  }
  
  @Test
  func basicChatFlow() async throws {
    let store = getStore()
    
    await store.send(.binding(.set(\.text, "Hello!"))) {
      $0.text = "Hello!"
      $0.isShowingSendButton = true
    }
    let userMessage = ChatMessage(id: UUID(0), text: "Hello!", role: .user, date: date)
    await store.send(.sendMessageButtonPressed) {
      $0.text = ""
      $0.isShowingSendButton = false
      $0.messages = [userMessage]
    }
    
    await store.receive(\.aiResponse.success) {
      $0.messages = [userMessage, aiResponse]
    }
  }
  
  @Test
  func emptyMessageIsNotSent() async throws {
    let store = getStore()
    
    #expect(store.state.text.isEmpty)
    #expect(store.state.isShowingSendButton == false)
    await store.send(.sendMessageButtonPressed)
  }
  
  @Test
  func fieldIsFocusedWhenViewAppearsWithEmptyChat() async throws {
    let store = getStore()
    
    await store.send(\.onAppear) {
      $0.focusedField = true
    }
  }
  
  @Test
  func fieldIsNotFocusedWhenViewAppearsWithChatNotEmpty() async throws {
    let store = getStore(messages: ChatMessage.mock)
    
    await store.send(\.onAppear)
  }
  
  @Test
  func sendButtonIsVisibleWhenViewAppearsWithTextFieldPopulated() async throws {
    let store = getStore(text: "Hello")
    
    await store.send(\.onAppear) {
      $0.focusedField = true
      $0.isShowingSendButton = true
    }
  }
}

// MARK: - Helpers
extension ChatTests {
  private func getStore(messages: [ChatMessage] = [], text: String = "") -> TestStore<Chat.State, Chat.Action> {
    TestStore(initialState: Chat.State(
      messages: messages,
      text: text
    )) {
      Chat()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.date.now = date
      $0.aiClient.sendMessage = { [aiResponse] _ in aiResponse }
    }
  }
}
