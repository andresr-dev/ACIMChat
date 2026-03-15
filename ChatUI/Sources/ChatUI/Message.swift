//
//  Message.swift
//  ChatUI
//
//  Created by Andres Raigoza on 14/03/26.
//

import Foundation

struct Message: Equatable, Identifiable {
  let id = UUID()
  var text: String
  var isAI: Bool
  var date: Date = .now
}

extension Message {
  static let mock = [
    Message(text: "This is a question in the chat, this is a question in the chat", isAI: false),
    Message(text: "This is an answer from the AI, this is an answer from the AI", isAI: true),
    Message(text: "This is another question in the chat, this is another question in the chat", isAI: false),
    Message(text: "This is another answer from the AI, this is an answer from the AI", isAI: true),
    Message(text: "This is yet another question in the chat, this is yet another question in the chat", isAI: false),
    Message(text: "This is yet another answer in the chat from AI, this is an answer from the AI", isAI: true),
  ]
}
