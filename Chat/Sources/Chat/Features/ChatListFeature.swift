//
//  ChatListFeature.swift
//  Chat
//
//  Created by Andres Raigoza on 25/03/26.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct ChatListFeature {
  @ObservableState
  public struct State: Equatable {
    @Shared(.chats) public var chats: IdentifiedArrayOf<ChatModel>
    var onAppearPerformed = false
    
    public init() { }
  }
  
  public enum Action {
    case onAppear
    case addChatButtonPressed
    case deleteButtonPressed(IndexSet)
    case addChat(ChatModel)
    case delegate(Delegate)
    
    @CasePathable
    public enum Delegate {
      case navigateTo(chat: Shared<ChatModel>)
    }
  }
  
  @Dependency(\.uuid) var uuid
  @Dependency(\.continuousClock) var clock
  
  public init() { }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard !state.onAppearPerformed else { return .none }
        state.onAppearPerformed = true
        
        if state.chats.isEmpty {
          let chat = ChatModel(id: uuid())
          state.$chats.withLock {
            _ = $0.append(chat)
          }
          if let sharedChat = Shared(state.$chats[id: chat.id]) {
            return .send(.delegate(.navigateTo(chat: sharedChat)))
          }
        }
        return .none
        
      case .addChatButtonPressed:
        return .run { [clock, uuid] send in
          let chat = ChatModel(id: uuid())
          await send(.addChat(chat), animation: .default)
          try await clock.sleep(for: .seconds(0.5))
          @Shared(.chats) var chats
          if let sharedChat = Shared($chats[id: chat.id]) {
            await send(.delegate(.navigateTo(chat: sharedChat)))
          }
        }
        
      case let .deleteButtonPressed(indexSet):
        for index in indexSet {
          state.$chats.withLock {
            _ = $0.remove(at: index)
          }
        }
        if state.chats.isEmpty {
          return .run { [clock, uuid] send in
            try await clock.sleep(for: .seconds(0.3))
            let chat = ChatModel(id: uuid())
            await send(.addChat(chat), animation: .default)
            try await clock.sleep(for: .seconds(0.3))
            @Shared(.chats) var chats
            if let sharedChat = Shared($chats[id: chat.id]) {
              await send(.delegate(.navigateTo(chat: sharedChat)))
            }
          }
        }
        return .none
        
      case let .addChat(chat):
        state.$chats.withLock {
          _ = $0.insert(chat, at: 0)
        }
        return .none
        
      case .delegate:
        return .none
      }
    }
  }
}
