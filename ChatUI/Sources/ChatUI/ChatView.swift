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
      .onChange(of: store.scrollPosition) { oldValue, newValue in
        withAnimation {
          proxy.scrollTo(newValue, anchor: .bottom)
        }
      }
      .task {
        proxy.scrollTo(store.chat.messages.last?.idString, anchor: .bottom)
      }
      .onChange(of: store.focusedField) { _, focused in
        if focused {
          Task { @MainActor in
            try await Task.sleep(for: .seconds(0.2))
            withAnimation {
              proxy.scrollTo(
                store.isTyping ? store.typingIndicatorID : store.chat.messages.last?.idString,
                anchor: .bottom
              )
            }
          }
        }
      }
      .onScrollGeometryChange(for: Bool.self, of: { geo in
        return geo.contentOffset.y < geo.contentSize.height - 100
      }, action: { oldValue, newValue in
        print("❤️ isScrolledToBottom: \(newValue)")
      })
    }
    .safeAreaInset(edge: .bottom) {
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
          ._printChanges()
      }
    )
  }
}
