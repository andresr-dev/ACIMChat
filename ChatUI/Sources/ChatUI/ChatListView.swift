//
//  ChatListView.swift
//  ChatUI
//
//  Created by Andres Raigoza on 25/03/26.
//

import ComposableArchitecture
import Chat
import SwiftUI

struct ChatListView: View {
  @Bindable var store: StoreOf<ChatListFeature>
  
  var body: some View {
    NavigationStack {
      List {
        ForEach(store.chats) { chat in
          Button {
            store.send(.chatSelected(chat))
          } label: {
            Text(chat.title)
          }
        }
      }
      .navigationTitle("Conversaciones")
      .navigationDestination(
        item: $store.scope(state: \.detail, action: \.detail)) { store in
          ChatView(store: store)
        }
    }
  }
}

#Preview {
  let chat = ChatFeature()
  ChatListView(
    store: Store(
      initialState: ChatListFeature.State(
        chats: [
          Chat(title: "Chat 1", messages: ChatMessage.mock),
          Chat(title: "Chat 2", messages: ChatMessage.mock),
          Chat(title: "Chat 3", messages: ChatMessage.mock),
          Chat(title: "Chat 4", messages: ChatMessage.mock)
        ]
      )
    ) {
      ChatListFeature()
    }
  )
}
