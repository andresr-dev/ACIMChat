//
//  Root.swift
//  Chat
//
//  Created by Andres Raigoza on 26/03/26.
//

import ComposableArchitecture

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
  }
  
  public init() { }
  
  public var body: some ReducerOf<Self> {
    Scope(state: \.chatList, action: \.chatList) {
      ChatList()
    }
    
    Reduce { state, action in
      switch action {
      case let .path(.element(id: _, action: .chat(.delegate(.chatUpdated(chat))))):
        state.chatList.chats[id: chat.id] = chat
        return .none
        
      case .path:
        return .none
        
      case let .chatList(chatListAction):
        switch chatListAction {
        case let .chatSelected(chat):
          state.path.append(.chat(Chat.State(chat: chat)))
          return .none
        case .onAppear:
          guard !state.onAppearPerformed else {
            return .none
          }
          state.onAppearPerformed = true
          if state.chatList.chats.count == 1, let chat = state.chatList.chats.first {
            state.path.append(.chat(Chat.State(chat: chat)))
          }
          return .none
        }
      }
    }
    .forEach(\.path, action: \.path)
  }
}
