//
//  RootTests.swift
//  Chat
//
//  Created by Andres Raigoza on 27/03/26.
//

@testable import Chat
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct RootTests {
  
  @Test func navigatesToFirstChatOnAppear() async throws {
    let store = TestStore(initialState: Root.State()) {
      Root()
    } withDependencies: {
      $0.uuid = .incrementing
    }
    
    let chat = ChatModel(id: UUID(0))
    
    await store.send(.chatList(.onAppear)) {
      $0.chatList = ChatList.State(chats: [chat])
      $0.onAppearPerformed = true
      $0.path[id: 0] = .chat(Chat.State(chat: chat))
    }
    
    await store.send(.path(.popFrom(id: 0))) {
      $0.path = StackState([])
    }
  }
  
  @Test func messagesPersistAfterNavigatingBack() async throws {
    let date = Date(timeIntervalSince1970: 0)
    let chatID = UUID(0)
    let chat = ChatModel(id: chatID)
    let aiMessage = ChatMessage(id: UUID(2), text: "AI response", role: .ai, date: date)
    
    let store = TestStore(
      initialState: Root.State(
        chatList: ChatList.State(chats: [chat])
      )
    ) {
      Root()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.date.now = date
      $0.continuousClock = .immediate
      $0.aiClient.sendMessage = { _ in
        aiMessage
      }
    }
    
    await store.send(.chatList(.chatSelected(chat))) {
      $0.path[id: 0] = .chat(Chat.State(chat: chat))
    }
    
    await store.send(.path(.element(id: 0, action: .chat(.binding(.set(\.text, "Hello")))))) {
      $0.path[id: 0, case: \.chat]?.text = "Hello"
    }
    
    let userMessage = ChatMessage(id: UUID(0), text: "Hello", role: .user, date: date, displayingDate: true)
    
    await store.send(.path(.element(id: 0, action: .chat(.sendMessageButtonPressed)))) {
      $0.path[id: 0, case: \.chat]?.chat.messages = [userMessage]
      $0.path[id: 0, case: \.chat]?.isTyping = true
      $0.path[id: 0, case: \.chat]?.text = ""
    }
    
    var updatedChat = chat
    updatedChat.messages = [userMessage]
    await store.receive(\.path[id: 0].chat.delegate.chatUpdated) {
      $0.chatList.chats = [updatedChat]
    }
    
    await store.receive(\.path[id: 0].chat.startScrollDelay)
    
    updatedChat.messages.append(aiMessage)
    await store.receive(\.path[id: 0].chat.aiResponse.success) {
      $0.path[id: 0, case: \.chat]?.isTyping = false
      $0.path[id: 0, case: \.chat]?.chat = updatedChat
    }
    
    await store.receive(\.path[id: 0].chat.delegate.chatUpdated) {
      $0.chatList.chats = [updatedChat]
    }
    
    await store.receive(\.path[id: 0].chat.scrollToBottom) {
      $0.path[id: 0, case: \.chat]?.scrollPosition = aiMessage.id
    }
    
    await store.send(.path(.popFrom(id: 0))) {
      $0.path.removeAll()
      $0.chatList.chats = [updatedChat]
    }
    
    await store.send(.chatList(.chatSelected(updatedChat))) {
      $0.path[id: 1] = .chat(Chat.State(chat: updatedChat))
    }
  }
  
  @Test func updatedChatMovesToTop() async throws {
    let date = Date(timeIntervalSince1970: 0)
    let chat1 = ChatModel(id: UUID(0))
    let chat2 = ChatModel(id: UUID(1))
    let aiMessage = ChatMessage(id: UUID(2), text: "AI response", role: .ai, date: date)
    
    let store = TestStore(
      initialState: Root.State(
        chatList: ChatList.State(chats: [chat1, chat2])
      )
    ) {
      Root()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.date.now = date
      $0.continuousClock = .immediate
      $0.aiClient.sendMessage = { _ in
        aiMessage
      }
    }
    store.exhaustivity = .off
    
    await store.send(.chatList(.chatSelected(chat2)))
    await store.send(.path(.element(id: 0, action: .chat(.binding(.set(\.text, "Hello"))))))
    
    let userMessage = ChatMessage(id: UUID(0), text: "Hello", role: .user, date: date, displayingDate: true)
    await store.send(.path(.element(id: 0, action: .chat(.sendMessageButtonPressed))))
    
    var updatedChat2 = chat2
    updatedChat2.messages = [userMessage]
    await store.receive(\.path[id: 0].chat.delegate.chatUpdated) {
      $0.chatList.chats = [updatedChat2, chat1]
    }
    await store.skipReceivedActions()
  }
  
  @Test func navigatesToFirstChatOnCreation() async throws {
    let date = Date(timeIntervalSince1970: 0)
    let chat = ChatModel(id: UUID(1))
    let aiMessage = ChatMessage(id: UUID(2), text: "AI response", role: .ai, date: date)
    
    let store = TestStore(
      initialState: Root.State(
        chatList: ChatList.State(chats: [chat])
      )
    ) {
      Root()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.date.now = date
      $0.continuousClock = .immediate
      $0.aiClient.sendMessage = { _ in
        aiMessage
      }
    }
    
    let newChat = ChatModel(id: UUID(0))
    await store.send(.chatList(.addChatButtonPressed)) {
      $0.chatList.chats = [newChat, chat]
    }
    
    await store.receive(\.startFirstChatNavigationDelay)
    await store.receive(\.navigateToFirstChat) {
      $0.path[id: 0] = .chat(Chat.State(chat: newChat))
    }
  }
}
