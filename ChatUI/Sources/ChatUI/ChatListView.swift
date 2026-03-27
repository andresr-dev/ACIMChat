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
  @Bindable var store: StoreOf<ChatList>
  
  var body: some View {
    List {
      ForEach(store.chats) { chat in
        Button {
          store.send(.chatSelected(chat))
        } label: {
          Text(chat.title)
        }
      }
    }
    .navigationTitle("Chats")
  }
}

#Preview {
  NavigationStack {
    ChatListView(
      store: Store(
        initialState: ChatList.State(
          chats: [
            ChatModel(title: "Chat 1", messages: ChatMessage.mock),
            ChatModel(title: "Chat 2", messages: ChatMessage.mock),
            ChatModel(title: "Chat 3", messages: ChatMessage.mock)
          ]
        )
      ) {
        ChatList()
      }
    )
  }
}
