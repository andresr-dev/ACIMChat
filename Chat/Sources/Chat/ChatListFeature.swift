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
    @Presents public var detail: ChatFeature.State?
    public var chats: IdentifiedArrayOf<Chat>
    
    public init(chats: IdentifiedArrayOf<Chat> = [], detail: ChatFeature.State? = nil) {
      self.chats = chats
      self.detail = detail
    }
  }
  
  public enum Action {
    case detail(PresentationAction<ChatFeature.Action>)
    case chatSelected(Chat)
  }
  
  public init() { }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .detail:
        return .none
        
      case let .chatSelected(chat):
        state.detail = ChatFeature.State(chat: chat)
        return .none
      }
    }
    .ifLet(\.$detail, action: \.detail) {
      ChatFeature()
    }
  }
}
