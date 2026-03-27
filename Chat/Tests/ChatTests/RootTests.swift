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
  
  @Test func basicFlow() async throws {
    let store = TestStore(initialState: Root.State()) {
      Root()
    } withDependencies: {
      $0.uuid = .incrementing
    }
    
    let chat = ChatModel(id: UUID(0), title: "Nueva Conversación")
    
    await store.send(.chatList(.onAppear)) {
      $0.chatList = ChatList.State(chats: [chat])
      $0.onAppearPerformed = true
      $0.path[id: 0] = .chat(Chat.State(chat: chat))
    }
    
    await store.send(.path(.popFrom(id: 0))) {
      $0.path.removeAll()
    }
  }
}
