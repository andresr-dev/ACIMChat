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
          HStack {
            Text(chat.title)
              .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.right")
              .font(.callout)
              .foregroundStyle(.secondary)
          }
        }
        .foregroundStyle(.primary)
      }
      .onDelete { indexSet in
        store.send(.deleteButtonPressed(indexSet))
      }
    }
    .navigationTitle("Chats")
    .toolbar {
      ToolbarItem {
        Button("Add", systemImage: "plus") {
          store.send(.addChatButtonPressed, animation: .default)
        }
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
  }
}

#Preview("Empty history") {
  NavigationStack {
    ChatListView(
      store: Store(
        initialState: ChatList.State()
      ) {
        ChatList()
      }
    )
  }
}

#Preview("Chat history") {
  NavigationStack {
    ChatListView(
      store: Store(
        initialState: ChatList.State(
          chats: [
            ChatModel(messages: ChatMessage.mock),
            ChatModel(messages: ChatMessage.mock),
            ChatModel(messages: ChatMessage.mock)
          ]
        )
      ) {
        ChatList()
      }
    )
  }
}
