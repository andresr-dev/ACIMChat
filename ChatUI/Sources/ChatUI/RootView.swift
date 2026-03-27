//
//  RootView.swift
//  ChatUI
//
//  Created by Andres Raigoza on 26/03/26.
//

import Chat
import ComposableArchitecture
import SwiftUI

struct RootView: View {
  @Bindable var store: StoreOf<RootFeature>
  
  var body: some View {
    NavigationStack(
      path: $store.scope(state: \.path, action: \.path)) {
        ChatListView(store: store.scope(state: \.chatList, action: \.chatList))
      } destination: { store in
        switch store.case {
        case .chat(let store):
          ChatView(store: store)
        }
      }
  }
}

#Preview {
  RootView(
    store: Store(
      initialState: RootFeature.State(
        path: StackState([.chat(ChatFeature.State(chat: Chat(title: "Chat 3", messages: ChatMessage.mock)))]),
        chatList: ChatListFeature.State(
          chats: [
            Chat(title: "Chat 1", messages: ChatMessage.mock),
            Chat(title: "Chat 2", messages: ChatMessage.mock),
            Chat(title: "Chat 3", messages: ChatMessage.mock)
          ]
        )
      )
    ) {
    RootFeature()
  })
}
