//
//  ACIMChatApp.swift
//  ACIMChat
//
//  Created by Andres Raigoza on 9/03/26.
//

import SwiftUI
import Chat
import ChatUI
import ComposableArchitecture

@main
struct ACIMChatApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  @State private var store = Store(initialState: Root.State()) {
    Root()
  }
  
  var body: some Scene {
    WindowGroup {
      RootView(store: store)
    }
  }
}
