//
//  Message.swift
//  ChatUI
//
//  Created by Andres Raigoza on 14/03/26.
//

import Foundation

public struct Message: Equatable, Identifiable, Sendable {
  public let id: UUID
  public let text: String
  public let role: Role
  public let date: Date
  
  public enum Role: String, Sendable {
    case user
    case ai = "assistant"
  }
  
  public init(id: UUID = UUID(), text: String, role: Role, date: Date = Date()) {
    self.id = id
    self.text = text
    self.role = role
    self.date = date
  }
}

extension Message {
  public static let mock = [
    Message(text: "This is a question in the chat, this is a question in the chat", role: .user),
    Message(text: "This is an answer from the AI, this is an answer from the AI", role: .ai),
    Message(text: "This is another question in the chat, this is another question in the chat", role: .user),
    Message(text: "This is another answer from the AI, this is an answer from the AI", role: .ai),
    Message(text: "This is yet another question in the chat, this is yet another question in the chat", role: .user),
    Message(text: "This is yet another answer in the chat from AI, this is an answer from the AI", role: .ai),
    Message(text: "This is a question in the chat, this is a question in the chat", role: .user),
    Message(text: "This is an answer from the AI, this is an answer from the AI", role: .ai),
    Message(text: "This is another question in the chat, this is another question in the chat", role: .user),
    Message(text: "This is another answer from the AI, this is an answer from the AI", role: .ai),
    Message(text: "This is yet another question in the chat, this is yet another question in the chat", role: .user),
    Message(text: "This is the last AI answer", role: .ai),
    Message(text: "This is the last question", role: .user),
  ]
}
