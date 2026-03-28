//
//  Root.swift
//  Chat
//
//  Created by Andres Raigoza on 26/03/26.
//

import ComposableArchitecture
import Foundation

extension Root.Path.State: Equatable { }

@Reducer
public struct Root {
  @Reducer
  public enum Path {
    case chat(Chat)
  }
  
  @ObservableState
  public struct State: Equatable {
    public var path: StackState<Path.State>
    public var chatList: ChatList.State
    var onAppearPerformed = false
    
    public init(path: StackState<Path.State> = StackState(), chatList: ChatList.State = ChatList.State()) {
      self.path = path
      self.chatList = chatList
    }
  }
  
  public enum Action {
    case path(StackActionOf<Path>)
    case chatList(ChatList.Action)
    case startFirstChatNavigationDelay
    case navigateToFirstChat
  }
  
  @Dependency(\.uuid) var uuid
  @Dependency(\.continuousClock) var clock
  
  public init() { }
  
  public var body: some ReducerOf<Self> {
    Scope(state: \.chatList, action: \.chatList) {
      ChatList()
    }
    
    Reduce { state, action in
      switch action {
      case let .path(.element(id: _, action: .chat(.delegate(.chatUpdated(chat))))):
        state.chatList.chats[id: chat.id] = chat
        if let index = state.chatList.chats.index(id: chat.id) {
          state.chatList.chats.move(fromOffsets: IndexSet(integer: index), toOffset: 0)
        }
        return .none
        
      case .chatList(.onAppear):
        guard !state.onAppearPerformed else {
          return .none
        }
        state.onAppearPerformed = true
        if let chat = state.chatList.chats.first {
          state.path.append(.chat(Chat.State(chat: chat)))
        }
        return .none
        
      case let .chatList(.chatSelected(chat)):
        state.path.append(.chat(Chat.State(chat: chat)))
        return .none
        
      case .chatList(.addChatButtonPressed):
        return .send(.startFirstChatNavigationDelay)
        
      case .startFirstChatNavigationDelay:
        return .run { [clock] send in
          try await clock.sleep(for: .seconds(0.5))
          await send(.navigateToFirstChat)
        }
        
      case .navigateToFirstChat:
        state.chatList.chats.first.map {
          state.path.append(.chat(Chat.State(chat: $0)))
        }
        return .none
        
      case .path, .chatList:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}
