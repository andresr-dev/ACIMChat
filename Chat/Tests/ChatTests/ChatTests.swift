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
  var aiResponse: Message {
    Message(id: UUID(1), text: "Hello there!", role: .ai, date: date)
  }
  
  @Test
  func basicChatFlow() async throws {
    let store = getStore()
    
    await store.send(\.textChanged, "Hello!") {
      $0.text = "Hello!"
      $0.isShowingSendButton = true
    }
    let firstUserMessage = Message(id: UUID(0), text: "Hello!", role: .user, date: date)
    await store.send(.sendMessageButtonPressed) {
      $0.text = ""
      $0.isShowingSendButton = false
      $0.messages = [firstUserMessage]
      $0.isTyping = true
    }
    await store.receive(\.aiResponse.success) {
      $0.isTyping = false
      $0.messages = [firstUserMessage, aiResponse]
    }
    
    await store.send(\.textChanged, "Hello again!") {
      $0.text = "Hello again!"
      $0.isShowingSendButton = true
    }
    let secondUserMessage = Message(id: UUID(1), text: "Hello again!", role: .user, date: date)
    await store.send(.sendMessageButtonPressed) {
      $0.text = ""
      $0.isShowingSendButton = false
      $0.messages = [firstUserMessage, aiResponse, secondUserMessage]
      $0.isTyping = true
    }
    await store.receive(\.aiResponse.success) {
      $0.isTyping = false
      $0.messages = [firstUserMessage, aiResponse, secondUserMessage, aiResponse]
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
    let store = getStore(messages: Message.mock)
    
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
  private func getStore(messages: [Message] = [], text: String = "") -> TestStore<Chat.State, Chat.Action> {
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
