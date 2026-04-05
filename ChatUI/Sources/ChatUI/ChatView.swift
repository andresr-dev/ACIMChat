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
  private let rowInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
  
  public init(store: StoreOf<Chat>) {
    self.store = store
  }
  
  public var body: some View {
    VStack {
      ScrollViewReader { proxy in
        List {
          ForEach(store.chat.messages) { message in
            MessageView(message: message)
              .id(message.idString)
              .listRowSeparator(.hidden)
              .listRowInsets(rowInsets)
          }
          
          if store.isTyping {
            TypingIndicator()
              .id(store.typingIndicatorID)
              .frame(maxWidth: .infinity, alignment: .leading)
              .listRowSeparator(.hidden)
              .listRowInsets(rowInsets)
          }
        }
        .listStyle(.plain)
        .listRowSpacing(12)
        .scrollDismissesKeyboard(.interactively)
        .defaultScrollAnchor(.bottom)
        .task(id: store.scrollToLastMessageTaskID) {
          proxy.scrollTo(store.chat.messages.last?.idString, anchor: .bottom)
        }
        .onChange(of: store.scrollPosition) { oldValue, newValue in
          withAnimation {
            proxy.scrollTo(newValue, anchor: .bottom)
          }
        }
        .onScrollGeometryChange(for: Bool.self, of: { geo in
          let bottomOffsetY = geo.contentOffset.y + geo.visibleRect.height
          let contentHeight = geo.contentSize.height
          return bottomOffsetY > contentHeight - 2
        }, action: { wasScrollAtBottom, isScrollAtBottom in
          store.send(.isScrollAtBottomChanged(isScrollAtBottom))
        })
      }
      
      MessageInputView(store: store)
        .padding([.horizontal, .bottom])
        .padding(.top, 6)
        .background {
          Color(.systemBackground)
            .ignoresSafeArea()
        }
    }
    .navigationTitle("UCDM")
    .navigationBarTitleDisplayMode(.inline)
    .alert($store.scope(state: \.alert, action: \.alert))
  }
}

#Preview {
  NavigationStack {
    ChatView(
      store: Store(
        initialState: Chat.State(chat: Shared(value: .mock))
      ) {
        Chat()
      }
    )
  }
}
