//
//  ChatView.swift
//  ChatUI
//
//  Created by Andres Raigoza on 14/03/26.
//

import Chat
import ComposableArchitecture
import SwiftUI

public struct ChatView: View {
  @Bindable var store: StoreOf<Chat>
  
  public init(store: StoreOf<Chat>) {
    self.store = store
  }
  
  public var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(store.messages) { message in
            VStack(alignment: .leading, spacing: 12) {
              MessageView(message: message)
              
              if store.messages.last == message, store.isTyping {
                TypingIndicator()
                  .transition(.identity)
              }
            }
            .id(message.id)
          }
        }
        .padding([.horizontal])
        .scrollTargetLayout()
      }
      .scrollDismissesKeyboard(.interactively)
      .defaultScrollAnchor(.bottom)
      .scrollPosition(id: $store.scrollPosition, anchor: .bottom)
      .padding(.top, 12)
      
      MessageInputView(store: store)
        .padding([.horizontal, .bottom])
        .padding(.top, 12)
        .background()
        .ignoresSafeArea()
    }
  }
}

#Preview {
  ChatView(
    store: Store(initialState: Chat.State()) {
      Chat()
        ._printChanges()
    }
  )
}
