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
  public struct State: Equatable {
    public var chats: IdentifiedArrayOf<ChatModel>
    
    public init(chats: IdentifiedArrayOf<ChatModel> = []) {
      self.chats = chats
    }
  }
  
  public enum Action {
    case onAppear
    case chatSelected(ChatModel)
  }
  
  @Dependency(\.uuid) var uuid
  
  public init() { }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        if state.chats.isEmpty {
          let chat = ChatModel(id: uuid(), title: "Nueva Conversación")
          state.chats.append(chat)
        }
        return .none
      case .chatSelected:
        return .none
      }
    }
  }
}
