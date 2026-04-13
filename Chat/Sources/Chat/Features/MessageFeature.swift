//
//  MessageFeature.swift
//  Chat
//
//  Created by Andres Raigoza on 11/04/26.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct MessageFeature {
  @ObservableState
  public struct State: Equatable, Identifiable {
    public let message: ChatMessage
    public var isSpeaking = false
    
    public var id: UUID { message.id }
    
    public init(message: ChatMessage) {
      self.message = message
    }
  }
  
  public enum Action: Equatable {
    case speakButtonPressed
    case didStopSpeaking
    case delegate(Delegate)
    
    @CasePathable
    public enum Delegate {
      case didStartSpeaking
    }
  }
  
  @Dependency(\.speechClient) var speech
  
  public init() { }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .speakButtonPressed:
        if state.isSpeaking {
          return .run { [speech] send in
            await speech.stop()
          }
        }
        state.isSpeaking = true
        
        return .run { [speech, text = state.message.text] send in
          await send(.delegate(.didStartSpeaking))
          try? await speech.speak(text: text, language: "es")
          await send(.didStopSpeaking)
        }
        
      case .didStopSpeaking:
        state.isSpeaking = false
        return .none
        
      case .delegate:
        return .none
      }
    }
  }
}
