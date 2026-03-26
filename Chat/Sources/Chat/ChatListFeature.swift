//
//  ChatListFeature.swift
//  Chat
//
//  Created by Andres Raigoza on 25/03/26.
//

import ComposableArchitecture

@Reducer
public struct ChatListFeature {
  @Reducer
  public enum Destination {
    case detail(ChatFeature)
  }
  
  @ObservableState
  public struct State {
    @Presents public var destination: Destination.State?
    public var chats: IdentifiedArrayOf<Chat>
    
    public init(chats: IdentifiedArrayOf<Chat> = [], destination: Destination.State? = nil) {
      self.chats = chats
      self.destination = destination
    }
  }
  
  public enum Action {
    case destination(PresentationAction<Destination.Action>)
    case chatSelected(Chat)
  }
  
  public init() { }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .destination:
        return .none
        
      case let .chatSelected(chat):
        state.destination = .detail(
          ChatFeature.State(chat: chat)
        )
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}
