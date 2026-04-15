//
//  ChatListFeatureTests.swift
//  Chat
//
//  Created by Andres Raigoza on 27/03/26.
//

@testable import Chat
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ChatListFeatureTests {
  
  @Test func appendsNewChatOnEmptyState() async throws {
    let store = getStore()
    
    await store.send(\.onAppear) {
      $0.onAppearPerformed = true
      $0.$chats.withLock { $0 = [ChatModel(id: UUID(0))] }
    }
    await store.receive(\.navigateTo)
  }
  
  @Test func doesNotAppendNewChatOnNonEmptyState() async throws {
    @Shared(.chats) var chats = [ChatModel(id: UUID(0))]
    let store = getStore()
    
    await store.send(\.onAppear) {
      $0.onAppearPerformed = true
    }
    await store.receive(\.navigateTo)
  }
  
  @Test func addsNewChat() async throws {
    let chat = ChatModel.mock
    @Shared(.chats) var chats = [chat]
    let store = getStore()
        
    await store.send(.addChatButtonPressed)
    await store.receive(\.addChat) {
      $0.$chats.withLock { $0 = [ChatModel(id: UUID(0)), chat] }
    }
    await store.receive(\.navigateTo)
  }
  
  @Test func chatDeletion() async throws {
    @Shared(.chats) var chats = [.mock]
    let store = getStore()
    
    await store.send(.deleteButtonPressed(IndexSet(integer: 0))) {
      $0.$chats.withLock { $0 = [] }
    }
    await store.receive(\.addChat) {
      $0.$chats.withLock { $0 = [ChatModel(id: UUID(0))] }
    }
    await store.receive(\.navigateTo)
  }
}

// MARK: - Helpers
extension ChatListFeatureTests {
  func getStore(
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) -> TestStoreOf<ChatListFeature> {
    TestStore(
      initialState: ChatListFeature.State(),
      reducer: { ChatListFeature() },
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
