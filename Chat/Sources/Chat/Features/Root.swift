//
//  Root.swift
//  Chat
//
//  Created by Andres Raigoza on 26/03/26.
//

import ComposableArchitecture

@Reducer
public struct Root {
  @Reducer
  public enum Path {
    case chat(Chat)
  }
  
  @ObservableState
  public struct State {
    public var path: StackState<Path.State>
    public var chatList: ChatList.State
    
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
      case .path:
        return .none
        
      case let .chatList(chatListAction):
        switch chatListAction {
        case .chatSelected(let chat):
          state.path.append(.chat(Chat.State(chat: chat)))
          return .none
        }
      }
    }
    .forEach(\.path, action: \.path)
  }
}
