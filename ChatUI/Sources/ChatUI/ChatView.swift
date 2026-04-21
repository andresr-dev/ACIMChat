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
  @Bindable var store: StoreOf<ChatFeature>
  private let rowInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
  
  public init(store: StoreOf<ChatFeature>) {
    self.store = store
  }
  
  public var body: some View {
    VStack {
      ScrollViewReader { proxy in
        List {
          ForEach(store.scope(state: \.messages, action: \.messages)) { store in
            MessageView(store: store)
              .id(store.message.idString)
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
        .animation(.default, value: store.messages)
        .scrollDismissesKeyboard(.interactively)
        .defaultScrollAnchor(.bottom)
        .onScrollGeometryChange(for: Bool.self, of: { geo in
          let bottomOffsetY = geo.contentOffset.y + geo.visibleRect.height
          let contentHeight = geo.contentSize.height
          return bottomOffsetY > contentHeight - 20
        }, action: { wasScrollAtBottom, isScrollAtBottom in
          store.send(.isScrollAtBottomChanged(isScrollAtBottom))
        })
        .task(id: store.scrollToLastMessageTaskID) {
          proxy.scrollTo(store.messages.last?.message.idString, anchor: .bottom)
        }
        .onChange(of: store.scrollPosition) { oldValue, newValue in
          withAnimation {
            proxy.scrollTo(newValue, anchor: .bottom)
          }
        }
      }
      
      MessageInputView(store: store)
        .padding([.horizontal, .bottom])
        .padding(.top, 6)
        .background {
          Color(.systemBackground)
            .ignoresSafeArea()
        }
        .overlay(alignment: .topTrailing) {
          if store.showingScrollToBottomButton {
            Button {
              store.send(.scrollToBottomButtonPressed)
            } label: {
              Image(systemName: "chevron.down")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 34, height: 34)
            }
            .tint(.primary)
            .glassEffect(.regular.interactive(), in: .circle)
            .padding(.trailing, 10)
            .offset(y: -60)
            .transition(.asymmetric(
              insertion: .opacity.animation(.default),
              removal: .identity
            ))
          }
        }
    }
    .navigationTitle("UCDM")
    .navigationBarTitleDisplayMode(.inline)
    .alert($store.scope(state: \.alert, action: \.alert))
  }
}

#Preview("Success") {
  NavigationStack {
    ChatView(
      store: Store(
        initialState: ChatFeature.State(text: "Hello")
      ) {
        ChatFeature()
          ._printChanges()
      }
    )
  }
}

#Preview("Failure") {
  NavigationStack {
    ChatView(
      store: Store(
        initialState: ChatFeature.State(text: "Hello")
      ) {
        ChatFeature()
          ._printChanges()
      } withDependencies: {
        $0.aiClient = .mock(.failure)
      }
    )
  }
}
