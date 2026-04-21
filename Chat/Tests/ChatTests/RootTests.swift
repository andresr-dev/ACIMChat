//
//  RootTests.swift
//  Chat
//
//  Created by Andres Raigoza on 27/03/26.
//

@testable import Chat
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct RootFeatureTests {
  
  @Test func chatNavigation() async throws {
    let chat = ChatModel(id: UUID(0))
    @Shared(.chats) var chats = [chat]
    let store = getStore()
        
    await store.send(.chatList(.navigateTo(chatID: chat.id))) {
      $0.path[id: 0] = .chat(ChatFeature.State(id: chat.id))
    }
    await store.send(.path(.popFrom(id: 0))) {
      $0.path = StackState([])
    }
  }
  
  @Test func messagesPersistAfterNavigatingBack() async throws {
    var chat = ChatModel(id: UUID(0))
    @Shared(.chats) var chats = [chat]
    let store = getStore()
        
    await store.send(.chatList(.navigateTo(chatID: chat.id))) {
      $0.path[id: 0] = .chat(ChatFeature.State(id: chat.id))
    }
    
    await store.send(.path(.element(id: 0, action: .chat(.binding(.set(\.text, "Hello")))))) {
      $0.path[id: 0, case: \.chat]?.text = "Hello"
    }
     
    chat.messages = [.mockUserMessage]
    await store.send(.path(.element(id: 0, action: .chat(.sendMessageButtonPressed)))) {
      $0.path[id: 0, case: \.chat]?.messages = [MessageFeature.State(message: .mockUserMessage)]
      $0.chatList.$chats.withLock { $0 = [chat] }
      $0.path[id: 0, case: \.chat]?.isTyping = true
      $0.path[id: 0, case: \.chat]?.text = ""
      $0.path[id: 0, case: \.chat]?.messages = [MessageFeature.State(message: .mockUserMessage)]
      $0.chatList.$chats.withLock { $0 = [chat] }
    }
    
    chat.messages.append(.mockAIMessage)
    await store.receive(\.path[id: 0].chat.delegate.chatUpdated) {
      $0.path[id: 0, case: \.chat]?.messages = [
        MessageFeature.State(message: .mockUserMessage)
      ]
      $0.chatList.$chats.withLock { $0 = [chat] }
    }
    await store.receive(\.path[id: 0].chat.scrollToBottom)
    
    await store.receive(\.path[id: 0].chat.aiResponse.success) {
      $0.path[id: 0, case: \.chat]?.isTyping = false
      $0.chatList.$chats.withLock { $0 = [chat] }
      $0.path[id: 0, case: \.chat]?.messages = [
        MessageFeature.State(message: .mockUserMessage),
        MessageFeature.State(message: .mockAIMessage)
      ]
    }
    await store.receive(\.path[id: 0].chat.delegate.chatUpdated)
    await store.receive(\.path[id: 0].chat.scrollToBottom)
    await store.receive(\.path[id: 0].chat.scrollToTypingIndicator) {
      $0.path[id: 0, case: \.chat]?.scrollPosition = "typing"
    }
    await store.receive(\.path[id: 0].chat.scrollToLastMessage) {
      $0.path[id: 0, case: \.chat]?.scrollPosition = ChatMessage.mockAIMessage.idString
    }
    await store.send(.path(.popFrom(id: 0))) {
      $0.path = StackState([])
    }
    await store.send(.chatList(.navigateTo(chatID: chat.id))) {
      $0.path[id: 1] = .chat(
        ChatFeature.State(
          id: chat.id,
          messages: [
            MessageFeature.State(message: .mockUserMessage),
            MessageFeature.State(message: .mockAIMessage)
          ]
        )
      )
    }
  }
  
  @Test func messageIsDeletedOnCancellationError() async throws {
    let chat = ChatModel(id: UUID(0))
    @Shared(.chats) var chats = [chat]
    let store = getStore(aiClient: .mock(.cancellation))
    store.exhaustivity = .off
    
    await store.send(.chatList(.navigateTo(chatID: chat.id))) {
      $0.path[id: 0] = .chat(ChatFeature.State(id: chat.id))
    }
    await store.send(.path(.element(id: 0, action: .chat(.binding(.set(\.text, "Hello")))))) {
      $0.path[id: 0, case: \.chat]?.text = "Hello"
    }
    
    await store.send(.path(.element(id: 0, action: .chat(.sendMessageButtonPressed)))) {
      $0.path[id: 0, case: \.chat]?.messages = [
        MessageFeature.State(message: .mockUserMessage)
      ]
      $0.path[id: 0, case: \.chat]?.isTyping = true
      $0.path[id: 0, case: \.chat]?.text = ""
    }
    await store.send(.path(.popFrom(id: 0))) {
      $0.path = StackState([])
      $0.chatList.$chats[id: chat.id].withLock {
        $0?.messages = []
      }
    }
  }
  
  @Test func messageIsDeletedOnURLCancellationError() async throws {
    let chat = ChatModel(id: UUID(0))
    @Shared(.chats) var chats = [chat]
    let store = getStore(aiClient: .mock(.urlCancellation))
    store.exhaustivity = .off
    
    await store.send(.chatList(.navigateTo(chatID: chat.id))) {
      $0.path[id: 0] = .chat(ChatFeature.State(id: chat.id))
    }
    await store.send(.path(.element(id: 0, action: .chat(.binding(.set(\.text, "Hello")))))) {
      $0.path[id: 0, case: \.chat]?.text = "Hello"
    }
    await store.send(.path(.element(id: 0, action: .chat(.sendMessageButtonPressed)))) {
      $0.path[id: 0, case: \.chat]?.messages = [
        MessageFeature.State(message: .mockUserMessage)
      ]
      $0.path[id: 0, case: \.chat]?.isTyping = true
      $0.path[id: 0, case: \.chat]?.text = ""
    }
    await store.send(.path(.popFrom(id: 0))) {
      $0.path = StackState([])
      $0.chatList.$chats[id: chat.id].withLock {
        $0?.messages = []
      }
    }
  }
  
  @Test func updatedChatMovesToTop() async throws {
    let chat1 = ChatModel(id: UUID(0))
    var chat2 = ChatModel(id: UUID(1))
    @Shared(.chats) var chats = [chat1, chat2]
    
    let store = getStore()
    store.exhaustivity = .off
    
    await store.send(.chatList(.navigateTo(chatID: chat2.id)))
    await store.send(.path(.element(id: 0, action: .chat(.binding(.set(\.text, "Hello"))))))
    await store.send(.path(.element(id: 0, action: .chat(.sendMessageButtonPressed))))
    
    chat2.messages = [.mockUserMessage, .mockAIMessage]
    await store.receive(\.path[id: 0].chat.delegate.chatUpdated) {
      $0.chatList.$chats.withLock { $0 = [chat2, chat1] }
    }
  }
}

// MARK: - Helpers
extension RootFeatureTests {
  func getStore(
    aiClient: AIClient = .mock(.success),
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) -> TestStoreOf<RootFeature> {
    TestStore(
      initialState: RootFeature.State(),
      reducer: { RootFeature() },
      withDependencies: {
        $0.aiClient = aiClient
        $0.date.now = Date(timeIntervalSince1970: 0)
        $0.continuousClock = .immediate
        $0.uuid = .incrementing
      },
      fileID: fileID,
      file: filePath,
      line: line,
      column: column
    )
  }
}
