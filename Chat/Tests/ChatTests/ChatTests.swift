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
  var userMessage: ChatMessage {
    ChatMessage(id: UUID(0), text: "Hello!", role: .user, date: date)
  }
  var aiResponse: ChatMessage {
    ChatMessage(id: UUID(1), text: "Hello there!", role: .ai, date: date)
  }
  
  @Test func basicChatFlow() async throws {
    let store = getStore()
    
    await store.send(.binding(.set(\.text, "Hello!"))) {
      $0.text = "Hello!"
    }
    
    await store.send(.sendMessageButtonPressed) {
      $0.messages = [userMessage]
      $0.isTyping = true
      $0.text = ""
    }
    await store.receive(\.startScrollDelay)
    
    await store.receive(\.aiResponse.success) {
      $0.isTyping = false
      $0.messages = [userMessage, aiResponse]
    }
    await store.receive(\.scrollToBottom) {
      $0.scrollPosition = aiResponse.id
    }
  }
  
  @Test func emptyMessageIsNotSent() async throws {
    let store = getStore()
    
    #expect(store.state.text.isEmpty)
    #expect(store.state.isShowingSendButton == false)
    await store.send(.sendMessageButtonPressed)
  }
  
  @Test func fieldIsFocusedWhenViewAppearsWithEmptyChat() async throws {
    let store = getStore()
    
    await store.send(\.onAppear) {
      $0.focusedField = true
    }
  }
  
  @Test func fieldIsNotFocusedWhenViewAppearsWithChatNotEmpty() async throws {
    let store = getStore(messages: ChatMessage.mock)
    
    await store.send(\.onAppear)
  }
  
  @Test func sendButtonIsVisibleWhenViewAppearsWithTextFieldPopulated() async throws {
    let store = getStore(text: "Hello")
    
    await store.send(\.onAppear) {
      $0.focusedField = true
    }
  }
  
  @Test func presentsAlertOnAIResponseError() async throws {
    let store = getStore(
      sendMessage: { _ in
        struct SomeError: Error { }
        throw SomeError()
      }
    )
    
    await store.send(.binding(.set(\.text, "Hello!"))) {
      $0.text = "Hello!"
    }
    
    await store.send(.sendMessageButtonPressed) {
      $0.messages = [userMessage]
      $0.isTyping = true
      $0.text = ""
    }
    await store.receive(\.startScrollDelay)
    
    await store.receive(\.aiResponse) {
      $0.isTyping = false
      $0.alert = Chat.errorAlert
    }
    await store.receive(\.scrollToBottom) {
      $0.scrollPosition = userMessage.id
    }
  }
}

// MARK: - Helpers
extension ChatTests {
  private func getStore(
    messages: [ChatMessage] = [],
    text: String = "",
    sendMessage: @escaping @Sendable ([ChatMessage]) async throws -> ChatMessage = { _ in
      ChatMessage(id: UUID(1), text: "Hello there!", role: .ai, date: Date(timeIntervalSince1970: 1234567890))
    },
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) -> TestStore<Chat.State, Chat.Action> {
    TestStore(
      initialState: Chat.State(
        messages: messages,
        text: text),
      reducer: { Chat() },
      withDependencies: {
        $0.uuid = .incrementing
        $0.date.now = date
        $0.aiClient.sendMessage = sendMessage
        $0.continuousClock = .immediate
      },
      fileID: fileID,
      file: filePath,
      line: line,
      column: column
    )
  }
}
