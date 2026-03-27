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
    let chats = IdentifiedArray(uniqueElements: [
      ChatModel(id: UUID(0), title: "Chat 1"),
      ChatModel(id: UUID(1), title: "Chat 2"),
      ChatModel(id: UUID(2), title: "Chat 3")
    ])
    
    let store = getStore(chats: chats)
    
    await store.send(\.onAppear)
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
