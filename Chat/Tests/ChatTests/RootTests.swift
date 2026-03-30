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
    let store = getStore(chats: [chat])
    
    await store.send(.chatList(.navigateTo(chat))) {
      $0.path[id: 0] = .chat(Chat.State(chat: chat))
    }
    
    await store.send(.path(.popFrom(id: 0))) {
      $0.path = StackState([])
    }
  }
  
  @Test func messagesPersistAfterNavigatingBack() async throws {
    let chat = ChatModel(id: UUID(0))
    let date = Date(timeIntervalSince1970: 0)
    let store = getStore(chats: [chat])
    
    await store.send(.chatList(.navigateTo(chat))) {
      $0.path[id: 0] = .chat(Chat.State(chat: chat))
    }
    
    await store.send(.path(.element(id: 0, action: .chat(.binding(.set(\.text, "Hello")))))) {
      $0.path[id: 0, case: \.chat]?.text = "Hello"
    }
        
    await store.send(.path(.element(id: 0, action: .chat(.sendMessageButtonPressed)))) {
      $0.path[id: 0, case: \.chat]?.chat.messages = [.mockUserMessage]
      $0.path[id: 0, case: \.chat]?.isTyping = true
      $0.path[id: 0, case: \.chat]?.text = ""
    }
    
    var updatedChat = chat
    updatedChat.messages = [.mockUserMessage]
    await store.receive(\.path[id: 0].chat.delegate.chatUpdated) {
      $0.chatList.chats = [updatedChat]
    }
    
    await store.receive(\.path[id: 0].chat.startScrollDelay)
    
    updatedChat.messages.append(.mockAIMessage)
    await store.receive(\.path[id: 0].chat.aiResponse.success) {
      $0.path[id: 0, case: \.chat]?.isTyping = false
      $0.path[id: 0, case: \.chat]?.chat = updatedChat
    }
    
    await store.receive(\.path[id: 0].chat.delegate.chatUpdated) {
      $0.chatList.chats = [updatedChat]
    }
    
    await store.receive(\.path[id: 0].chat.scrollToBottom) {
      $0.path[id: 0, case: \.chat]?.scrollPosition = ChatMessage.mockAIMessage.id
    }
    
    await store.send(.path(.popFrom(id: 0))) {
      $0.path.removeAll()
      $0.chatList.chats = [updatedChat]
    }
    
    await store.send(.chatList(.navigateTo(updatedChat))) {
      $0.path[id: 1] = .chat(Chat.State(chat: updatedChat))
    }
  }
  
  @Test func updatedChatMovesToTop() async throws {
    let chat1 = ChatModel(id: UUID(0))
    let chat2 = ChatModel(id: UUID(1))
    
    let store = getStore(chats: [chat1, chat2])
    store.exhaustivity = .off
    
    await store.send(.chatList(.navigateTo(chat2)))
    await store.send(.path(.element(id: 0, action: .chat(.binding(.set(\.text, "Hello"))))))
    
    await store.send(.path(.element(id: 0, action: .chat(.sendMessageButtonPressed))))
    
    var updatedChat2 = chat2
    updatedChat2.messages = [.mockUserMessage]
    await store.receive(\.path[id: 0].chat.delegate.chatUpdated) {
      $0.chatList.chats = [updatedChat2, chat1]
    }
    await store.skipReceivedActions()
  }
}

// MARK: - Helpers
extension RootTests {
  func getStore(
    chats: IdentifiedArrayOf<ChatModel> = [],
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) -> TestStoreOf<Root> {
    TestStore(
      initialState: Root.State(
        chatList: ChatList.State(chats: chats)
      ),
      reducer: { Root() },
      withDependencies: {
        $0.aiClient = AIClient.mock(.success)
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
