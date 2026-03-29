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
        moveChatToTop(state: &state, chatID: chat.id)
        return .none
        
      case let .chatList(.navigateTo(chat)):
        state.path = StackState([.chat(Chat.State(chat: chat))])
        return .none
        
      case .path, .chatList:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
  
  func moveChatToTop(state: inout State, chatID: ChatModel.ID) {
    if let index = state.chatList.chats.index(id: chatID) {
      state.chatList.chats.move(fromOffsets: IndexSet(integer: index), toOffset: 0)
    }
  }
}
