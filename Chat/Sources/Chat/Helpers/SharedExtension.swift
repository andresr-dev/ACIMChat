//
//  SharedExtension.swift
//  Chat
//
//  Created by Andres Raigoza on 31/03/26.
//

import ComposableArchitecture
import Foundation

public extension SharedKey where Self == FileStorageKey<IdentifiedArrayOf<ChatModel>>.Default {
  static var chats: Self {
    Self[.fileStorage(.documentsDirectory.appending(path: "chats.json")), default: []]
  }
}
