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
struct RootTests {
  
  @Test func chatNavigation() async throws {
    let chat = ChatModel(id: UUID(0))
    @Shared(.chats) var chats = [chat]
    let store = getStore()
    
    let sharedChat = try #require(Shared($chats[id: chat.id]))
    
    await store.send(.chatList(.navigateTo(chatID: chat.id))) {
      $0.path[id: 0] = .chat(ChatFeature.State(chat: sharedChat))
    }
    
    await store.send(.path(.popFrom(id: 0))) {
      $0.path = StackState([])
    }
  }
  
  @Test func messagesPersistAfterNavigatingBack() async throws {
    let chat = ChatModel(id: UUID(0))
    @Shared(.chats) var chats = [chat]
    let store = getStore()
    
    let sharedChat = try #require(Shared($chats[id: chat.id]))
    
    await store.send(.chatList(.navigateTo(chatID: chat.id))) {
      $0.path[id: 0] = .chat(ChatFeature.State(chat: sharedChat))
    }
    
    await store.send(.path(.element(id: 0, action: .chat(.binding(.set(\.text, "Hello")))))) {
      $0.path[id: 0, case: \.chat]?.text = "Hello"
    }
    
    var updatedChat = chat
    updatedChat.messages = [.mockUserMessage]
    
    await store.send(.path(.element(id: 0, action: .chat(.sendMessageButtonPressed)))) {
      $0.path[id: 0, case: \.chat]?.$chat.withLock { $0.messages = [.mockUserMessage] }
      $0.path[id: 0, case: \.chat]?.isTyping = true
      $0.path[id: 0, case: \.chat]?.text = ""
      $0.path[id: 0, case: \.chat]?.$chat.withLock {
        $0 = updatedChat
      }
    }
    
    updatedChat.messages.append(.mockAIMessage)
    await store.receive(\.path[id: 0].chat.delegate.chatUpdated) {
      $0.path[id: 0, case: \.chat]?.$chat.withLock {
        $0 = updatedChat
      }
    }
    await store.receive(\.path[id: 0].chat.scrollToBottom)
    await store.receive(\.path[id: 0].chat.aiResponse.success) {
      $0.path[id: 0, case: \.chat]?.isTyping = false
      $0.chatList.$chats.withLock { $0 = [updatedChat] }
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
    await store.send(.chatList(.navigateTo(chatID: updatedChat.id))) {
      $0.path[id: 1] = .chat(ChatFeature.State(chat: Shared(value: updatedChat)))
    }
  }
  
  @Test func messageIsDeletedOnCancellationError() async throws {
    let chat = ChatModel(id: UUID(0))
    @Shared(.chats) var chats = [chat]
    let store = getStore(aiClient: .mock(.cancellation))
    store.exhaustivity = .off
    
    let sharedChat = try #require(Shared($chats[id: chat.id]))
    await store.send(.chatList(.navigateTo(chatID: chat.id))) {
      $0.path[id: 0] = .chat(ChatFeature.State(chat: sharedChat))
    }
    await store.send(.path(.element(id: 0, action: .chat(.binding(.set(\.text, "Hello")))))) {
      $0.path[id: 0, case: \.chat]?.text = "Hello"
    }
    var updatedChat = chat
    updatedChat.messages = [.mockUserMessage]
    await store.send(.path(.element(id: 0, action: .chat(.sendMessageButtonPressed)))) {
      $0.path[id: 0, case: \.chat]?.$chat.withLock { $0.messages = [.mockUserMessage] }
      $0.path[id: 0, case: \.chat]?.isTyping = true
      $0.path[id: 0, case: \.chat]?.text = ""
      $0.path[id: 0, case: \.chat]?.$chat.withLock {
        $0 = updatedChat
      }
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
    
    let sharedChat = try #require(Shared($chats[id: chat.id]))
    await store.send(.chatList(.navigateTo(chatID: chat.id))) {
      $0.path[id: 0] = .chat(ChatFeature.State(chat: sharedChat))
    }
    await store.send(.path(.element(id: 0, action: .chat(.binding(.set(\.text, "Hello")))))) {
      $0.path[id: 0, case: \.chat]?.text = "Hello"
    }
    var updatedChat = chat
    updatedChat.messages = [.mockUserMessage]
    await store.send(.path(.element(id: 0, action: .chat(.sendMessageButtonPressed)))) {
      $0.path[id: 0, case: \.chat]?.$chat.withLock { $0.messages = [.mockUserMessage] }
      $0.path[id: 0, case: \.chat]?.isTyping = true
      $0.path[id: 0, case: \.chat]?.text = ""
      $0.path[id: 0, case: \.chat]?.$chat.withLock {
        $0 = updatedChat
      }
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
    let chat2 = ChatModel(id: UUID(1))
    @Shared(.chats) var chats = [chat1, chat2]
    
    let store = getStore()
    store.exhaustivity = .off
    
    await store.send(.chatList(.navigateTo(chatID: chat2.id)))
    await store.send(.path(.element(id: 0, action: .chat(.binding(.set(\.text, "Hello"))))))
    await store.send(.path(.element(id: 0, action: .chat(.sendMessageButtonPressed))))
    
    var updatedChat2 = chat2
    updatedChat2.messages = [.mockUserMessage, .mockAIMessage]
    await store.receive(\.path[id: 0].chat.delegate.chatUpdated) {
      $0.chatList.$chats.withLock { $0 = [updatedChat2, chat1] }
    }
  }
}

// MARK: - Helpers
extension RootTests {
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
