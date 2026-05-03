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
      $0.$chat.withLock { $0.messages = [userMessage] }
      $0.messages = [MessageFeature.State(message: userMessage)]
      $0.isTyping = true
      $0.text = ""
      $0.focusedField = false
    }
    await store.receive(\.scrollToLastUserMessage) {
      $0.scrollPosition = .user(userMessage.id.uuidString)
      $0.$chat.withLock { $0.messages = [userMessage, aiMessage] }
    }
    await store.receive(\.delegate.moveChatToTop)
    await store.receive(\.aiResponse.success) {
      $0.isTyping = false
      $0.aiResponseInProgressID = aiMessage.id
      $0.messages = [
        MessageFeature.State(message: userMessage),
        MessageFeature.State(message: aiMessage)
      ]
    }
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
      $0.$chat.withLock {
        $0.messages = [userMessage, aiMessage, secondUserMessage]
      }
      $0.isTyping = true
      $0.text = ""
      $0.focusedField = false
    }
    
    let secondAIResponse = ChatMessage(id: UUID(3), text: "Hello there!", role: .ai, date: nextDayDate)
    await store.receive(\.scrollToLastUserMessage) {
      $0.scrollPosition = .user(secondUserMessage.id.uuidString)
      $0.$chat.withLock {
        $0.messages = [
          userMessage, aiMessage, secondUserMessage, secondAIResponse
        ]
      }
    }
    await store.receive(\.delegate.moveChatToTop)
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
    let store = getStore(chat: Shared(value: .mock))
    
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
      $0.$chat.withLock { $0.messages = [userMessage] }
      $0.messages = [MessageFeature.State(message: userMessage)]
      $0.isTyping = true
      $0.text = ""
    }
    
    await store.receive(\.scrollToLastUserMessage) {
      $0.scrollPosition = .user(userMessage.id.uuidString)
    }
    await store.receive(\.delegate.moveChatToTop)
    await store.receive(\.aiResponse.failure) {
      $0.isTyping = false
      $0.alert = .error
    }
    await store.receive(\.aiResponseFinished)
    
    await store.send(.alert(.presented(.confirm))) {
      $0.$chat.withLock { $0.messages = [] }
      $0.alert = nil
    }
    await store.receive(\.deleteMessage) {
      $0.messages = []
    }
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
    let store = getStore()
    
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
    let message1 = ChatMessage.mockUserMessage
    let message2 = ChatMessage.mockAIMessage
    let store = getStore(
      chat: Shared(value: ChatModel(messages: [message1, message2]))
    )
    store.exhaustivity = .off
  
    await store.send(.messages(.element(id: message1.id, action: .speakButtonPressed))) {
      $0.messages[0].isSpeaking = true
    }
    await store.receive(\.messages[id: message1.id].delegate.stopOtherSpeakers)
    await store.send(.messages(.element(id: message2.id, action: .speakButtonPressed))) {
      $0.messages[0].isSpeaking = false
      $0.messages[1].isSpeaking = true
    }
  }
  
  @Test func generatesChatTitle() async throws {
    let userMessage = ChatMessage(
      id: UUID(0),
      text: "What is love?",
      role: .user,
      date: Date(timeIntervalSince1970: 0),
      displayingDate: true
    )
    let aiResponse = ChatMessage(
      id: UUID(1),
      text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
      role: .ai,
      date: Date(timeIntervalSince1970: 0)
    )
    let store = getStore(
      aiClient: AIClient(
        sendMessage: { _ in
          AsyncThrowingStream { continuation in
            continuation.yield("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.")
            continuation.finish()
          }
        },
        generateTitle: { question, answer in
          "Chat title"
        }
      )
    )
    await store.send(.binding(.set(\.text, "What is love?"))) {
      $0.text = "What is love?"
    }
    await store.send(.sendMessageButtonPressed) {
      $0.$chat.withLock {
        $0.messages = [userMessage]
      }
      $0.messages = [MessageFeature.State(message: userMessage)]
      $0.isTyping = true
      $0.text = ""
    }
    await store.receive(\.scrollToLastUserMessage) {
      $0.scrollPosition = .user(userMessage.id.uuidString)
      $0.$chat.withLock {
        $0.title = "Chat title"
      }
    }
    await store.receive(\.delegate.moveChatToTop)
    await store.receive(\.aiResponse) {
      $0.messages = [
        MessageFeature.State(message: userMessage),
        MessageFeature.State(message: aiResponse)
      ]
      $0.isTyping = false
      $0.aiResponseInProgressID = aiResponse.id
    }
    await store.receive(\.aiResponseFinished) {
      $0.aiResponseInProgressID = nil
    }
    await store.receive(\.titleGenerated)
    
    await store.send(.binding(.set(\.text, "Who am I?"))) {
      $0.text = "Who am I?"
    }
    let userMessage2 = ChatMessage(
      id: UUID(2),
      text: "Who am I?",
      role: .user,
      date: Date(timeIntervalSince1970: 0)
    )
    await store.send(.sendMessageButtonPressed) {
      $0.$chat.withLock {
        $0.messages = [userMessage, aiResponse, userMessage2]
      }
      $0.messages = [
        MessageFeature.State(message: userMessage),
        MessageFeature.State(message: aiResponse),
        MessageFeature.State(message: userMessage2)
      ]
      $0.isTyping = true
      $0.text = ""
    }
    let aiResponse2 = ChatMessage(
      id: UUID(3),
      text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
      role: .ai,
      date: Date(timeIntervalSince1970: 0)
    )
    await store.receive(\.scrollToLastUserMessage) {
      $0.$chat.withLock {
        $0.messages = [userMessage, aiResponse, userMessage2, aiResponse2]
      }
      $0.scrollPosition = .user(userMessage2.id.uuidString)
    }
    await store.receive(\.delegate.moveChatToTop)
    await store.receive(\.aiResponse) {
      $0.messages = [
        MessageFeature.State(message: userMessage),
        MessageFeature.State(message: aiResponse),
        MessageFeature.State(message: userMessage2),
        MessageFeature.State(message: aiResponse2)
      ]
      $0.isTyping = false
      $0.aiResponseInProgressID = aiResponse2.id
    }
    await store.receive(\.aiResponseFinished) {
      $0.aiResponseInProgressID = nil
    }
  }
}

// MARK: - Helpers
extension ChatFeatureTests {
  private func getStore(
    chat: Shared<ChatModel> = .init(value: ChatModel()),
    text: String = "",
    aiClient: AIClient = AIClient.mock(.success),
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) -> TestStore<ChatFeature.State, ChatFeature.Action> {
    TestStore(
      initialState: ChatFeature.State(chat: chat, text: text),
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
