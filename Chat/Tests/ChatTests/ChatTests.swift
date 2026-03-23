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
  
  @Test func basicChatFlow() async throws {
    let store = getStore()
    
    await store.send(.binding(.set(\.text, "Hello!"))) {
      $0.text = "Hello!"
    }
    
    let userMessage = ChatMessage(id: UUID(0), text: "Hello!", role: .user, date: date)
    await store.send(.sendMessageButtonPressed) {
      $0.messages = [userMessage]
      $0.isTyping = true
      $0.text = ""
    }
    
    let aiResponse = ChatMessage(id: UUID(1), text: "Hello there!", role: .ai, date: date)
    await store.receive(\.startScrollDelay)
    await store.receive(\.aiResponse.success) {
      $0.isTyping = false
      $0.messages = [userMessage, aiResponse]
    }
    await store.receive(\.scrollToBottom) {
      $0.scrollPosition = UUID(1)
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
  
//  @Test func historyDoesNotExceedElevenMessages() async throws {
//    var messagesSent = [ChatMessage]()
//    let store = getStore(
//      sendMessage: { messages in
//        messagesSent = messages
//        return messages[0]
//      }
//    )
//  }
}

// MARK: - Helpers
extension ChatTests {
  private func getStore(
    messages: [ChatMessage] = [],
    text: String = "",
    sendMessage: @escaping @Sendable ([ChatMessage]) -> ChatMessage = { _ in ChatMessage(id: UUID(1), text: "Hello there!", role: .ai, date: Date(timeIntervalSince1970: 1234567890)) }
  ) -> TestStore<Chat.State, Chat.Action> {
    TestStore(initialState: Chat.State(
      messages: messages,
      text: text
    )) {
      Chat()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.date.now = date
      $0.aiClient.sendMessage = sendMessage
      $0.continuousClock = .immediate
    }
  }
}
