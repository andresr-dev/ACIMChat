//
//  ChatTests.swift
//  Chat
//
//  Created by Andres Raigoza on 16/03/26.
//

import Testing
@testable import Chat
import ComposableArchitecture
import Foundation

struct ChatTests {
  let date = Date(timeIntervalSince1970: 1234567890)
  var aiResponse: Message {
    Message(id: UUID(1), text: "Hello there!", role: .ai, date: date)
  }
  
  @Test
  func basicChatFlow() async throws {
    let userMessage = Message(id: UUID(0), text: "Hello!", role: .user, date: date)
    
    let store = await TestStore(initialState: Chat.State()) {
      Chat()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.date.now = date
      $0.aiClient.sendMessage = { _ in aiResponse }
    }
    
    await store.send(\.textChanged, "Hello!") {
      $0.text = "Hello!"
      $0.isShowingSendButton = true
    }
    await store.send(.sendMessageButtonPressed) {
      $0.text = ""
      $0.isShowingSendButton = false
      $0.messages = [userMessage]
      $0.isTyping = true
    }
    await store.receive(\.aiResponse.success) {
      $0.isTyping = false
      $0.messages = [userMessage, aiResponse]
    }
  }
  
  @Test
  func userCannotSendEmptyMessage() async throws {
    let store = await TestStore(initialState: Chat.State()) {
      Chat()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.date.now = date
      $0.aiClient.sendMessage = { _ in aiResponse }
    }
    
    await store.send(.sendMessageButtonPressed)
  }
}
