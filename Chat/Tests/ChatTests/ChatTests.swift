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
      $0.chat.messages = [userMessage]
      $0.isTyping = true
      $0.text = ""
    }
    
    await store.receive(\.delegate)
    await store.receive(\.startScrollDelay)
    
    await store.receive(\.aiResponse.success) {
      $0.isTyping = false
      $0.chat.messages = [userMessage, aiMessage]
    }
    await store.receive(\.delegate)
    
    await store.receive(\.scrollToBottom) {
      $0.scrollPosition = aiMessage.id
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
      $0.chat.messages = [userMessage, aiMessage, secondUserMessage]
      $0.isTyping = true
      $0.text = ""
    }
    await store.receive(\.delegate)
    await store.receive(\.startScrollDelay)
    
    await store.receive(\.aiResponse.success) {
      $0.isTyping = false
      $0.chat.messages = [userMessage, aiMessage, secondUserMessage, secondAIResponse]
    }
    await store.receive(\.delegate)
    await store.receive(\.scrollToBottom) {
      $0.scrollPosition = secondAIResponse.id
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
    
    await store.receive(\.scrollToBottom)
  }
  
  @Test func fieldIsNotFocusedWhenViewAppearsWithChatNotEmpty() async throws {
    let chat = ChatModel.mock
    let store = getStore(chat: chat)
    
    await store.send(\.onAppear)
    await store.receive(\.scrollToBottom) {
      $0.scrollPosition = chat.messages.last!.id
    }
  }
  
  @Test func sendButtonIsVisibleWhenViewAppearsWithTextFieldPopulated() async throws {
    let store = getStore(text: "Hello")
    
    await store.send(\.onAppear) {
      $0.focusedField = true
    }
    await store.receive(\.scrollToBottom)
  }
  
  @Test func presentsAlertOnAIResponseError() async throws {
    let store = getStore(aiClient: .failure)
    
    await store.send(.binding(.set(\.text, "Hello"))) {
      $0.text = "Hello"
    }
       
    let userMessage = ChatMessage.mockUserMessage
    
    await store.send(.sendMessageButtonPressed) {
      $0.chat.messages = [userMessage]
      $0.isTyping = true
      $0.text = ""
    }
    
    await store.receive(\.delegate)
    
    await store.receive(\.startScrollDelay)
    
    await store.receive(\.aiResponse) {
      $0.isTyping = false
      $0.alert = .error
    }
    await store.receive(\.scrollToBottom) {
      $0.scrollPosition = userMessage.id
    }
  }
}

// MARK: - Helpers
extension ChatTests {
  private func getStore(
    chat: ChatModel = ChatModel(),
    text: String = "",
    aiClient: AIClient = AIClient.success,
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
