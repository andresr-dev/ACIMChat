//
//  ChatListTests.swift
//  Chat
//
//  Created by Andres Raigoza on 27/03/26.
//

@testable import Chat
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ChatListTests {
  
  @Test func appendsNewChatOnEmptyState() async throws {
    let store = getStore()
    
    await store.send(\.onAppear) {
      $0.chats = [ChatModel(id: UUID(0), title: "Nueva Conversación")]
    }
  }
  
  @Test func doesNotAppendNewChatOnNonEmptyState() async throws {
    let store = getStore(chats: [ChatModel(id: UUID(0), title: "New Chat")])
    
    await store.send(\.onAppear)
  }
  
  @Test func addsNewChatOnPressingPlusButton() async throws {
    let chat = ChatModel.mock
    let store = getStore(chats: [chat])
        
    await store.send(.addChatButtonPressed) {
      $0.chats = [ChatModel(id: UUID(0), title: "Nueva Conversación"), chat]
    }
  }
}

// MARK: - Helpers
extension ChatListTests {
  func getStore(chats: IdentifiedArrayOf<ChatModel> = []) -> TestStoreOf<ChatList> {
    TestStore(initialState: ChatList.State(chats: chats)) {
      ChatList()
    } withDependencies: {
      $0.uuid = .incrementing
    }
  }
}
