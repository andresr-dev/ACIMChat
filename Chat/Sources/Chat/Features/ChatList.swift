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
    
    public init(chats: IdentifiedArrayOf<ChatModel> = []) {
      self.chats = chats
    }
  }
  
  public enum Action {
    case onAppear
    case addChatButtonPressed
    case chatSelected(ChatModel)
    case deleteButtonPressed(IndexSet)
  }
  
  @Dependency(\.uuid) var uuid
  
  public init() { }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        addNewChatIfNeeded(into: &state)
        return .none
        
      case .addChatButtonPressed:
        let chat = ChatModel(id: uuid())
        state.chats.insert(chat, at: 0)
        return .none
        
      case .chatSelected:
        return .none
        
      case let .deleteButtonPressed(indexSet):
        for index in indexSet {
          state.chats.remove(at: index)
        }
        addNewChatIfNeeded(into: &state)
        return .none
      }
    }
  }
  
  func addNewChatIfNeeded(into state: inout State) {
    if state.chats.isEmpty {
      let chat = ChatModel(id: uuid())
      state.chats.append(chat)
    }
  }
}
