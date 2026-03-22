//
//  File.swift
//  Chat
//
//  Created by Andres Raigoza on 21/03/26.
//

import ComposableArchitecture

@Reducer
public struct ChatInput {
  @ObservableState
  public struct State {
    public var text = ""
    public var isShowingSendButton: Bool {
      !text.isEmpty
    }
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case sendMessageButtonPressed
    case delegate(Delegate)
    
    public enum Delegate {
      case sendMessage(String)
    }
  }
  
  @Dependency(\.aiClient) var aiClient
  @Dependency(\.uuid) var uuid
  @Dependency(\.date.now) var now
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .sendMessageButtonPressed:
        guard !state.text.isEmpty else { return .none }
        let text = state.text
        state.text = ""
        return .send(.delegate(.sendMessage(text)))
        
      case .delegate:
        return .none
        
      case .binding:
        return .none
      }
    }
  }
}
