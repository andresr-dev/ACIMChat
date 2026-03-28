//
//  ChatModel.swift
//  ChatUI
//
//  Created by Andres Raigoza on 14/03/26.
//

import Foundation

public struct ChatModel: Equatable, Identifiable, Sendable {
  public let id: UUID
  public var title: String
  public var messages: [ChatMessage]
  
  public init(id: UUID = UUID(), title: String = "", messages: [ChatMessage] = []) {
    self.id = id
    self.title = title
    self.messages = messages
  }
}

public extension ChatModel {
  static var mock: ChatModel {
    ChatModel(title: "New Chat", messages: ChatMessage.mock)
  }
}

public struct ChatMessage: Equatable, Identifiable, Sendable {
  public let id: UUID
  public let text: String
  public let role: Role
  public let date: Date
  public let displayingDate: Bool
  
  public enum Role: String, Sendable {
    case user
    case ai = "assistant"
  }
  
  public init(id: UUID = UUID(), text: String, role: Role, date: Date = Date(), displayingDate: Bool = false) {
    self.id = id
    self.text = text
    self.role = role
    self.date = date
    self.displayingDate = displayingDate
  }
}

extension ChatMessage {
  public static let mock = [
    ChatMessage(text: "This is a question in the chat, this is a question in the chat", role: .user),
    ChatMessage(text: "This is an answer from the AI, this is an answer from the AI", role: .ai),
    ChatMessage(text: "This is another question in the chat, this is another question in the chat", role: .user),
    ChatMessage(text: "This is another answer from the AI, this is an answer from the AI", role: .ai),
    ChatMessage(text: "This is yet another question in the chat, this is yet another question in the chat", role: .user),
    ChatMessage(text: "This is yet another answer in the chat from AI, this is an answer from the AI", role: .ai),
    ChatMessage(text: "This is a question in the chat, this is a question in the chat", role: .user),
    ChatMessage(text: "This is an answer from the AI, this is an answer from the AI", role: .ai),
    ChatMessage(text: "This is another question in the chat, this is another question in the chat", role: .user),
    ChatMessage(text: "This is another answer from the AI, this is an answer from the AI", role: .ai),
    ChatMessage(text: "This is yet another question in the chat, this is yet another question in the chat", role: .user),
    ChatMessage(text: "This is the last AI answer", role: .ai),
    ChatMessage(text: "This is the last question", role: .user),
  ]
}
