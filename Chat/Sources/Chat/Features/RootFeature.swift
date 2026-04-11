//
//  RootFeature.swift
//  Chat
//
//  Created by Andres Raigoza on 26/03/26.
//

import ComposableArchitecture
import Foundation

extension RootFeature.Path.State: Equatable { }

@Reducer
public struct RootFeature {
  @Reducer
  public enum Path {
    case chat(ChatFeature)
  }
  
  @ObservableState
  public struct State: Equatable {
    public var path: StackState<Path.State>
    public var chatList: ChatListFeature.State
    @SharedReader(.chats) var chats
    
    public init(path: StackState<Path.State> = StackState(), chatList: ChatListFeature.State = ChatListFeature.State()) {
      self.path = path
      self.chatList = chatList
    }
  }
  
  public enum Action {
    case path(StackActionOf<Path>)
    case chatList(ChatListFeature.Action)
  }
  
  public init() { }
  
  public var body: some ReducerOf<Self> {
    Scope(state: \.chatList, action: \.chatList) {
      ChatListFeature()
    }
    
    Reduce { state, action in
      switch action {
      case let .path(.element(id: _, action: .chat(.delegate(actionDelegate)))):
        switch actionDelegate {
        case let .chatUpdated(id: chatID):
          moveChatToTop(state: &state, chatID: chatID)
          return .none
        }
        
      case let .chatList(.navigateTo(chatID: chatID)):
        guard let chat = Shared(state.chatList.$chats[id: chatID]) else {
          return .none
        }
        state.path = StackState([.chat(ChatFeature.State(chat: chat))])
        return .none
        
      case .path, .chatList:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
  
  private func moveChatToTop(state: inout State, chatID: ChatModel.ID) {
    guard let index = state.chatList.chats.index(id: chatID),
          index > 0 else {
      return
    }
    state.chatList.$chats.withLock {
      $0.move(fromOffsets: IndexSet(integer: index), toOffset: 0)
    }
  }
}
