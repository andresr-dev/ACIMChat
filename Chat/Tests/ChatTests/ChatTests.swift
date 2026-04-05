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
import Synchronization

@MainActor
struct ChatTests {
  
  @Test func basicChatFlow() async throws {
    let store = getStore()
    
    await store.send(.binding(.set(\.text, "Hello"))) {
      $0.text = "Hello"
    }
    
    let userMessage = ChatMessage.mockUserMessage
    let aiMessage = ChatMessage.mockAIMessage

    await store.send(.sendMessageButtonPressed) {
      $0.$chat.messages.withLock { $0 = [userMessage] }
      $0.isTyping = true
      $0.text = ""
    }
    
    await store.receive(\.delegate) {
      $0.$chat.messages.withLock { $0 = [userMessage, aiMessage] }
    }
    
    await store.receive(\.scrollToBottom)
    
    await store.receive(\.aiResponse.success) {
      $0.isTyping = false
    }
    await store.receive(\.delegate)
    
    await store.receive(\.scrollToTypingIndicator) {
      $0.scrollPosition = "typing"
    }
    
    await store.receive(\.scrollToBottom) {
      $0.scrollPosition = nil
    }
    
    await store.receive(\.scrollToLastMessage) {
      $0.scrollPosition = aiMessage.idString
    }
    
    await store.send(.binding(.set(\.text, "Hello Again!"))) {
      $0.text = "Hello Again!"
    }
    let nextDayDate = userMessage.date.addingTimeInterval(60 * 60 * 24)
    store.dependencies.date.now = nextDayDate
    
    let secondAIResponse = ChatMessage(id: UUID(3), text: "Hello there!", role: .ai, date: nextDayDate)
    store.dependencies.aiClient.sendMessage = { _ in
      secondAIResponse
    }
    
    let secondUserMessage = ChatMessage(id: UUID(1), text: "Hello Again!", role: .user, date: nextDayDate, displayingDate: true)
    
    await store.send(.sendMessageButtonPressed) {
      $0.$chat.messages.withLock {
        $0 = [userMessage, aiMessage, secondUserMessage]
      }
      $0.isTyping = true
      $0.text = ""
    }
    await store.receive(\.delegate) {
      $0.$chat.messages.withLock {
        $0 = [userMessage, aiMessage, secondUserMessage, secondAIResponse]
      }
    }
    
    await store.receive(\.scrollToBottom) {
      $0.scrollPosition = nil
    }
    
    await store.receive(\.aiResponse.success) {
      $0.isTyping = false
    }
    
    await store.receive(\.delegate)
    
    await store.receive(\.scrollToTypingIndicator) {
      $0.scrollPosition = "typing"
    }
    
    await store.receive(\.scrollToBottom) {
      $0.scrollPosition = nil
    }
    
    await store.receive(\.scrollToLastMessage) {
      $0.scrollPosition = secondAIResponse.idString
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
    let chat = ChatModel.mock
    let store = getStore(chat: Shared(value: chat))
    
    await store.send(\.onAppear)
  }
  
  @Test func sendButtonIsVisibleWhenViewAppearsWithTextFieldPopulated() async throws {
    let store = getStore(text: "Hello")
    
    await store.send(\.onAppear) {
      $0.focusedField = true
    }
  }
  
  @Test func presentsAlertOnAIResponseError() async throws {
    let store = getStore(aiClient: .mock(.failure))
    
    await store.send(.binding(.set(\.text, "Hello"))) {
      $0.text = "Hello"
    }
       
    let userMessage = ChatMessage.mockUserMessage
    
    await store.send(.sendMessageButtonPressed) {
      $0.$chat.messages.withLock { $0 = [userMessage] }
      $0.isTyping = true
      $0.text = ""
    }
    
    await store.receive(\.delegate)
    
    await store.receive(\.scrollToBottom)
        
    await store.receive(\.aiResponse) {
      $0.isTyping = false
      $0.alert = .error
    }
    await store.receive(\.scrollToTypingIndicator) {
      $0.scrollPosition = "typing"
    }
  }
  
  @Test func scrollsToBottomOnTextFieldIncreasedHeight() async throws {
    let store = getStore()
    
    await store.send(.isScrollAtBottomChanged(true)) {
      $0.isScrollAtBottom = true
    }
    
    await store.send(.textFieldHeightIncreased) {
      $0.scrollToLastMessageTaskID = UUID(0)
    }
  }
}

// MARK: - Helpers
extension ChatTests {
  private func getStore(
    chat: Shared<ChatModel> = Shared(value: ChatModel()),
    text: String = "",
    aiClient: AIClient = AIClient.mock(.success),
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) -> TestStore<Chat.State, Chat.Action> {
    TestStore(
      initialState: Chat.State(chat: chat, text: text),
      reducer: { Chat() },
      withDependencies: {
        $0.uuid = .incrementing
        $0.continuousClock = .immediate
        $0.date.now = Date(timeIntervalSince1970: 0)
        $0.aiClient = aiClient
      },
      fileID: fileID,
      file: filePath,
      line: line,
      column: column
    )
  }
}
