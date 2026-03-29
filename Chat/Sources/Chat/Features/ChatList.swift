//
//  ChatList.swift
//  Chat
//
//  Created by Andres Raigoza on 25/03/26.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct ChatList {
  
  @ObservableState
  public struct State: Equatable {
    public var chats: IdentifiedArrayOf<ChatModel>
    var onAppearPerformed = false
    
    public init(chats: IdentifiedArrayOf<ChatModel> = []) {
      self.chats = chats
    }
  }
  
  public enum Action {
    case onAppear
    case addChatButtonPressed
    case deleteButtonPressed(IndexSet)
    case navigateTo(ChatModel)
    case addChat(ChatModel)
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
          state.chats.append(chat)
        }
        guard let chat = state.chats.first else { return .none }
        return .send(.navigateTo(chat))
        
      case .addChatButtonPressed:
        return .run { [clock, uuid] send in
          let chat = ChatModel(id: uuid())
          await send(.addChat(chat), animation: .default)
          try await clock.sleep(for: .seconds(0.5))
          await send(.navigateTo(chat))
        }
        
      case let .deleteButtonPressed(indexSet):
        for index in indexSet {
          state.chats.remove(at: index)
        }
        if state.chats.isEmpty {
          return .run { [clock, uuid] send in
            try await clock.sleep(for: .seconds(0.3))
            let chat = ChatModel(id: uuid())
            await send(.addChat(chat), animation: .default)
            try await clock.sleep(for: .seconds(0.3))
            await send(.navigateTo(chat))
          }
        }
        return .none
        
      case let .addChat(chat):
        state.chats.insert(chat, at: 0)
        return .none
        
      case .navigateTo:
        return .none
      }
    }
  }
}
