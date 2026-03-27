//
//  RootView.swift
//  ChatUI
//
//  Created by Andres Raigoza on 26/03/26.
//

import Chat
import ComposableArchitecture
import SwiftUI

public struct RootView: View {
  @Bindable var store: StoreOf<Root>
  
  public init(store: StoreOf<Root>) {
    self.store = store
  }
  
  public var body: some View {
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
      initialState: Root.State(
        path: StackState([.chat(Chat.State(chat: ChatModel(title: "Chat 3", messages: ChatMessage.mock)))]),
        chatList: ChatList.State(
          chats: [
            ChatModel(title: "Chat 1", messages: ChatMessage.mock),
            ChatModel(title: "Chat 2", messages: ChatMessage.mock),
            ChatModel(title: "Chat 3", messages: ChatMessage.mock)
          ]
        )
      )
    ) {
    Root()
  })
}
