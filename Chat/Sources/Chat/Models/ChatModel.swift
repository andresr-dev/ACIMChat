//
//  ChatModel.swift
//  ChatUI
//
//  Created by Andres Raigoza on 14/03/26.
//

import ComposableArchitecture
import Foundation

public struct ChatModel: Equatable, Identifiable, Codable, Sendable {
  public let id: UUID
  public var messages: IdentifiedArrayOf<ChatMessage>
  public var title: String?
  
  public init(id: UUID = UUID(), messages: IdentifiedArrayOf<ChatMessage> = []) {
    self.id = id
    self.messages = messages
  }
}

public extension ChatModel {
  static var mock: ChatModel {
    ChatModel(
      messages: [
        ChatMessage(text: "This is a question in the chat, this is a question in the chat", role: .user, displayingDate: true),
        ChatMessage(text: "This is an answer from the AI, this is an answer from the AI", role: .ai),
        ChatMessage(text: "This is another question in the chat, this is another question in the chat", role: .user),
        ChatMessage(text: "This is another answer from the AI, this is an answer from the AI", role: .ai),
        ChatMessage(text: "This is yet another question in the chat, this is yet another question in the chat", role: .user),
        ChatMessage(text: "This is yet another answer in the chat from AI, this is an answer from the AI", role: .ai),
        ChatMessage(text: "This is a question in the chat, this is a question in the chat", role: .user),
        ChatMessage(text: "This is an answer from the AI, this is an answer from the AI", role: .ai),
        ChatMessage(text: "This is another question in the chat, this is another question in the chat", role: .user),
        ChatMessage(text: "This is another answer from the AI, this is an answer from the AI", role: .ai)
      ]
    )
  }
}

public struct ChatMessage: Equatable, Identifiable, Codable, Sendable {
  public let id: UUID
  public var text: String
  public let role: Role
  public let date: Date
  public let displayingDate: Bool
  
  public enum Role: String, Codable, Sendable {
    case user
    case ai = "assistant"
  }
  
  public init(id: UUID = UUID(), text: String = "", role: Role, date: Date = Date(), displayingDate: Bool = false) {
    self.id = id
    self.text = text
    self.role = role
    self.date = date
    self.displayingDate = displayingDate
  }
}

public extension ChatMessage {
  static let mockUserMessage = ChatMessage(id: UUID(0), text: "Hello", role: .user, date: Date(timeIntervalSince1970: 0), displayingDate: true)
  
  static let mockAIMessage = ChatMessage(id: UUID(1), text: "Hello", role: .ai, date: Date(timeIntervalSince1970: 0))
}
