//
//  ChatListFeature.swift
//  Chat
//
//  Created by Andres Raigoza on 25/03/26.
//

import ComposableArchitecture

@Reducer
public struct ChatListFeature {
  
  @ObservableState
  public struct State {
    public var chats: IdentifiedArrayOf<Chat>
    
    public init(chats: IdentifiedArrayOf<Chat> = []) {
      self.chats = chats
    }
  }
  
  public enum Action {
    case chatSelected(Chat)
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
