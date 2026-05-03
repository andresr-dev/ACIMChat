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
        
    await store.send(.chatList(.delegate(.navigateTo(chat: $chats[0])))) {
      $0.path[id: 0] = .chat(ChatFeature.State(chat: $chats[0]))
    }
    await store.send(.path(.popFrom(id: 0))) {
      $0.path = StackState([])
    }
  }
  
  @Test func messagesPersistAfterNavigatingBack() async throws {
    var chat = ChatModel(id: UUID(0))
    let userMessage = ChatMessage.mockUserMessage
    let aiMessage = ChatMessage.mockAIMessage
    @Shared(.chats) var chats = [chat]
    let store = getStore()
        
    await store.send(.chatList(.delegate(.navigateTo(chat: $chats[0])))) {
      $0.path[id: 0] = .chat(ChatFeature.State(chat: $chats[0]))
    }
    
    await store.send(.path(.element(id: 0, action: .chat(.binding(.set(\.text, "Hello")))))) {
      $0.path[id: 0, case: \.chat]?.text = "Hello"
    }
     
    chat.messages = [userMessage]
    await store.send(.path(.element(id: 0, action: .chat(.sendMessageButtonPressed)))) {
      $0.path[id: 0, case: \.chat]?.messages = [MessageFeature.State(message: userMessage)]
      $0.chatList.$chats.withLock { $0 = [chat] }
      $0.path[id: 0, case: \.chat]?.isTyping = true
      $0.path[id: 0, case: \.chat]?.text = ""
      $0.chatList.$chats.withLock { $0 = [chat] }
    }
    
    chat.messages.append(aiMessage)
    await store.receive(\.path[id: 0].chat.scrollToLastUserMessage) {
      $0.chatList.$chats.withLock { $0 = [chat] }
      $0.path[id: 0, case: \.chat]?.messages = [
        MessageFeature.State(message: userMessage)
      ]
      $0.path[id: 0, case: \.chat]?.scrollPosition = .user(userMessage.id.uuidString)
    }
    await store.receive(\.path[id: 0].chat.delegate.moveChatToTop)
    await store.receive(\.path[id: 0].chat.aiResponse.success) {
      $0.path[id: 0, case: \.chat]?.isTyping = false
      $0.path[id: 0, case: \.chat]?.messages = [
        MessageFeature.State(message: userMessage),
        MessageFeature.State(message: aiMessage)
      ]
      $0.path[id: 0, case: \.chat]?.aiResponseInProgressID = chat.messages.last?.id
    }
    await store.receive(\.path[id: 0].chat.aiResponseFinished) {
      $0.path[id: 0, case: \.chat]?.aiResponseInProgressID = nil
    }
    await store.send(.path(.popFrom(id: 0))) {
      $0.path = StackState([])
    }
    await store.send(.chatList(.delegate(.navigateTo(chat: $chats[0])))) {
      $0.path[id: 1] = .chat(
        ChatFeature.State(chat: $chats[0])
      )
    }
  }
  
  @Test func messageIsDeletedOnCancellationError() async throws {
    let chat = ChatModel(id: UUID(0))
    @Shared(.chats) var chats = [chat]
    let store = getStore(aiClient: .mock(.cancellation))
    store.exhaustivity = .off
    
    await store.send(.chatList(.delegate(.navigateTo(chat: $chats[0])))) {
      $0.path[id: 0] = .chat(ChatFeature.State(chat: $chats[0]))
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
    
    await store.send(.chatList(.delegate(.navigateTo(chat: $chats[0])))) {
      $0.path[id: 0] = .chat(ChatFeature.State(chat: $chats[0]))
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
    let chat2 = ChatModel(id: UUID(1))
    @Shared(.chats) var chats = [chat1, chat2]
    
    let store = getStore()
    store.exhaustivity = .off
    
    await store.send(.chatList(.delegate(.navigateTo(chat: $chats[1]))))
    await store.send(.path(.element(id: 0, action: .chat(.binding(.set(\.text, "Hello"))))))
    await store.send(.path(.element(id: 0, action: .chat(.sendMessageButtonPressed))))
    
    await store.receive(\.path[id: 0].chat.delegate.moveChatToTop)
    await store.skipReceivedActions()
    
    #expect(chats.elements.map(\.id) == [chat2.id, chat1.id])
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
