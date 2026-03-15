//
//  ACIMChatApp.swift
//  ACIMChat
//
//  Created by Andres Raigoza on 9/03/26.
//

import SwiftUI
import ChatUI

@main
struct ACIMChatApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  var body: some Scene {
    WindowGroup {
      ChatView()
    }
  }
}
