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
      $0.onAppearPerformed = true
      $0.chats = [ChatModel(id: UUID(0))]
    }
    await store.receive(\.navigateTo)
  }
  
  @Test func doesNotAppendNewChatOnNonEmptyState() async throws {
    let store = getStore(chats: [ChatModel(id: UUID(0))])
    
    await store.send(\.onAppear) {
      $0.onAppearPerformed = true
    }
    await store.receive(\.navigateTo)
  }
  
  @Test func addsNewChat() async throws {
    let chat = ChatModel.mock
    let store = getStore(chats: [chat])
        
    await store.send(.addChatButtonPressed)
    await store.receive(\.addChat) {
      $0.chats = [ChatModel(id: UUID(0)), chat]
    }
    await store.receive(\.navigateTo)
  }
  
  @Test func chatDeletion() async throws {
    let chat = ChatModel.mock
    let store = getStore(chats: [chat])
    
    await store.send(.deleteButtonPressed(IndexSet(integer: 0))) {
      $0.chats = []
    }
    await store.receive(\.addChat) {
      $0.chats = [ChatModel(id: UUID(0))]
    }
    await store.receive(\.navigateTo)
  }
}

// MARK: - Helpers
extension ChatListTests {
  func getStore(
    chats: IdentifiedArrayOf<ChatModel> = [],
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) -> TestStoreOf<ChatList> {
    TestStore(
      initialState: ChatList.State(chats: chats),
      reducer: { ChatList() },
      withDependencies: {
        $0.uuid = .incrementing
        $0.continuousClock = .immediate
      },
      fileID: fileID,
      file: filePath,
      line: line,
      column: column
    )
  }
}
