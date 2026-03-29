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
      $0.chats = [ChatModel(id: UUID(0))]
    }
  }
  
  @Test func doesNotAppendNewChatOnNonEmptyState() async throws {
    let store = getStore(chats: [ChatModel(id: UUID(0))])
    
    await store.send(\.onAppear)
  }
  
  @Test func addsNewChatToTopOnPressingPlusButton() async throws {
    let chat = ChatModel.mock
    let store = getStore(chats: [chat])
        
    await store.send(.addChatButtonPressed) {
      $0.chats = [ChatModel(id: UUID(0)), chat]
    }
  }
  
  @Test func chatDeletion() async throws {
    let chat = ChatModel.mock
    let store = getStore(chats: [chat])
    
    await store.send(.deleteButtonPressed(IndexSet(integer: 0))) {
      $0.chats = [ChatModel(id: UUID(0))]
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
