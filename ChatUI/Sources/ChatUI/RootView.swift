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
  @Bindable var store: StoreOf<RootFeature>
  
  public init(store: StoreOf<RootFeature>) {
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
    store: Store(initialState: RootFeature.State()) {
      RootFeature()
        ._printChanges()
    }
  )
}
