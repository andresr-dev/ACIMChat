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
  @State var position = ScrollPosition(idType: Message.ID.self)
  
  public init(store: StoreOf<Chat>) {
    self.store = store
  }
  
  public var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(store.messages, content: MessageView.init)
          
          if store.state.isTyping {
            TypingIndicator()
              .frame(maxWidth: .infinity, alignment: .leading)
              .transition(
                .asymmetric(
                  insertion: .opacity,
                  removal: .identity
                )
              )
          }
        }
        .padding([.horizontal])
        .scrollTargetLayout()
      }
      .defaultScrollAnchor(.bottom)
      .scrollPosition($position, anchor: .bottom)
      .scrollDismissesKeyboard(.interactively)
      .onChange(of: store.messages) { _, newValue in
        if let id = newValue.last?.id {
          position.scrollTo(id: id, anchor: .bottom)
        }
      }
      .animation(.easeOut, value: store.messages)
      .animation(.easeOut, value: position)
      .animation(.default, value: store.isTyping)
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
    }
  )
}
