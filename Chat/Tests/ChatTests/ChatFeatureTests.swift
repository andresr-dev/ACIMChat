//
//  ChatFeatureTests.swift
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
struct ChatFeatureTests {
  
  @Test func basicChatFlow() async throws {
    let store = getStore()
    
    await store.send(.binding(.set(\.text, "Hello"))) {
      $0.text = "Hello"
    }
    
    let userMessage = ChatMessage.mockUserMessage
    let aiMessage = ChatMessage.mockAIMessage
    
    await store.send(.sendMessageButtonPressed) {
      $0.messages = [
        MessageFeature.State(message: userMessage)
      ]
      $0.isTyping = true
      $0.text = ""
    }
    await store.receive(\.delegate.chatUpdated)
    await store.receive(\.scrollToLastUserMessage) {
      $0.scrollPosition = .user(userMessage.id.uuidString)
    }
    await store.receive(\.aiResponse.success) {
      $0.isTyping = false
      $0.aiResponseInProgressID = aiMessage.id
      $0.messages = [
        MessageFeature.State(message: userMessage),
        MessageFeature.State(message: aiMessage)
      ]
    }
    await store.receive(\.delegate.chatUpdated)
    await store.receive(\.aiResponseFinished) {
      $0.aiResponseInProgressID = nil
    }
    await store.send(.binding(.set(\.text, "Hello Again!"))) {
      $0.text = "Hello Again!"
    }
    let nextDayDate = userMessage.date.addingTimeInterval(60 * 60 * 24)
    store.dependencies.date.now = nextDayDate
    
    store.dependencies.aiClient.sendMessage = { _ in
      AsyncThrowingStream { continuation in
        continuation.yield("Hello there!")
        continuation.finish()
      }
    }
    
    let secondUserMessage = ChatMessage(id: UUID(2), text: "Hello Again!", role: .user, date: nextDayDate, displayingDate: true)
    await store.send(.sendMessageButtonPressed) {
      $0.messages = [
        MessageFeature.State(message: userMessage),
        MessageFeature.State(message: aiMessage),
        MessageFeature.State(message: secondUserMessage)
      ]
      $0.isTyping = true
      $0.text = ""
    }
    await store.receive(\.delegate.chatUpdated)
    
    let secondAIResponse = ChatMessage(id: UUID(3), text: "Hello there!", role: .ai, date: nextDayDate)
    await store.receive(\.scrollToLastUserMessage) {
      $0.scrollPosition = .user(secondUserMessage.id.uuidString)
    }
    await store.receive(\.aiResponse.success) {
      $0.isTyping = false
      $0.aiResponseInProgressID = secondAIResponse.id
      $0.messages = [
        MessageFeature.State(message: userMessage),
        MessageFeature.State(message: aiMessage),
        MessageFeature.State(message: secondUserMessage),
        MessageFeature.State(message: secondAIResponse)
      ]
    }
    await store.receive(\.delegate.chatUpdated)
    await store.receive(\.aiResponseFinished) {
      $0.aiResponseInProgressID = nil
    }
  }
  
  @Test func fieldIsFocusedWhenViewAppearsWithEmptyChat() async throws {
    let store = getStore()
    
    await store.send(\.onAppear) {
      $0.focusedField = true
    }
  }
  
  @Test func fieldIsNotFocusedWhenViewAppearsWithNonEmptyChat() async throws {
    let messages = [
      MessageFeature.State(message: .mockUserMessage),
      MessageFeature.State(message: .mockAIMessage),
    ]
    let store = getStore(messages: messages)
    
    await store.send(\.onAppear)
  }
  
  @Test func sendButtonIsVisibleWhenViewAppearsWithTextFieldPopulated() async throws {
    let store = getStore(text: "Hello")
    
    await store.send(\.onAppear) {
      $0.focusedField = true
    }
  }
  
  @Test func deletesMessageOnAIResponseError() async throws {
    let store = getStore(aiClient: .mock(.failure))
    
    await store.send(.binding(.set(\.text, "Hello"))) {
      $0.text = "Hello"
    }
    
    let userMessage = ChatMessage.mockUserMessage
    await store.send(.sendMessageButtonPressed) {
      $0.messages = [MessageFeature.State(message: userMessage)]
      $0.isTyping = true
      $0.text = ""
    }
    
    await store.receive(\.delegate.chatUpdated)
    await store.receive(\.scrollToLastUserMessage) {
      $0.scrollPosition = .user(userMessage.id.uuidString)
    }
    await store.receive(\.aiResponse.failure) {
      $0.isTyping = false
      $0.alert = .error
    }
    await store.receive(\.aiResponseFinished)
    
    await store.send(.alert(.presented(.confirm))) {
      $0.alert = nil
    }
    await store.receive(\.deleteMessage) {
      $0.messages = []
    }
    await store.receive(\.delegate.chatUpdated)
  }
  
  @Test func scrollsToBottomOnTextFieldIncreasedHeight() async throws {
    let store = getStore()
    
    await store.send(.isScrollAtBottomChanged(true)) {
      $0.isScrollAtBottom = true
    }
    await store.receive(\.updateShowingScrollToBottomButton)
    await store.send(.textFieldHeightIncreased) {
      $0.scrollToLastMessageTaskID = UUID(0)
    }
  }
  
  @Test func showsScrollToBottomButton() async throws {
    let messages = [
      MessageFeature.State(message: .mockUserMessage),
      MessageFeature.State(message: .mockAIMessage),
    ]
    let store = getStore(messages: messages)
    
    await store.send(.isScrollAtBottomChanged(true)) {
      $0.isScrollAtBottom = true
    }
    await store.receive(\.updateShowingScrollToBottomButton)
    await store.send(.isScrollAtBottomChanged(false)) {
      $0.isScrollAtBottom = false
    }
    await store.receive(\.updateShowingScrollToBottomButton) {
      $0.showingScrollToBottomButton = true
    }
  }
  
  @Test func stopsSpeakingMessageOnDidStartSpeaking() async throws {
    var message1 = MessageFeature.State(message: .mockUserMessage)
    message1.isSpeaking = true
    let message2 = MessageFeature.State(message: .mockAIMessage)
    let messages = [message1, message2]
    let store = getStore(messages: messages)
    
    await store.send(.messages(.element(id: message2.id, action: .delegate(.didStartSpeaking)))) {
      $0.messages[0].isSpeaking = false
    }
  }
}

// MARK: - Helpers
extension ChatFeatureTests {
  private func getStore(
    messages: [MessageFeature.State] = [],
    text: String = "",
    aiClient: AIClient = AIClient.mock(.success),
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) -> TestStore<ChatFeature.State, ChatFeature.Action> {
    TestStore(
      initialState: ChatFeature.State(id: UUID(), messages: messages, text: text),
      reducer: { ChatFeature() },
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
