//
//  ChatList.swift
//  Chat
//
//  Created by Andres Raigoza on 25/03/26.
//

import ComposableArchitecture

@Reducer
public struct ChatList {
  
  @ObservableState
  public struct State {
    public var chats: IdentifiedArrayOf<ChatModel>
    
    public init(chats: IdentifiedArrayOf<ChatModel> = []) {
      self.chats = chats
    }
  }
  
  public enum Action {
    case chatSelected(ChatModel)
  }
  
  public init() { }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .chatSelected:
        return .none
      }
    }
  }
}
