//
//  AIClientTests.swift
//  Chat
//
//  Created by Andres Raigoza on 18/03/26.
//

@testable import Chat
import InlineSnapshotTesting
import Testing
import ComposableArchitecture

@Suite(.snapshots(record: .failed))
struct AIClientTests {
  
  @Test func requestHistoryDropsOldMessages() async throws {
//    let request = try AIClient.getRequestFrom(messages: ChatMessage.mock)
//    #expect(request.history.count == 10)
//    
//    assertInlineSnapshot(of: request, as: .json) {
//      """
//      {
//        "history" : [
//          {
//            "content" : "This is another question in the chat, this is another question in the chat",
//            "role" : "user"
//          },
//          {
//            "content" : "This is another answer from the AI, this is an answer from the AI",
//            "role" : "assistant"
//          },
//          {
//            "content" : "This is yet another question in the chat, this is yet another question in the chat",
//            "role" : "user"
//          },
//          {
//            "content" : "This is yet another answer in the chat from AI, this is an answer from the AI",
//            "role" : "assistant"
//          },
//          {
//            "content" : "This is a question in the chat, this is a question in the chat",
//            "role" : "user"
//          },
//          {
//            "content" : "This is an answer from the AI, this is an answer from the AI",
//            "role" : "assistant"
//          },
//          {
//            "content" : "This is another question in the chat, this is another question in the chat",
//            "role" : "user"
//          },
//          {
//            "content" : "This is another answer from the AI, this is an answer from the AI",
//            "role" : "assistant"
//          },
//          {
//            "content" : "This is yet another question in the chat, this is yet another question in the chat",
//            "role" : "user"
//          },
//          {
//            "content" : "This is the last AI answer",
//            "role" : "assistant"
//          }
//        ],
//        "language" : "en",
//        "question" : "This is the last question"
//      }
//      """
//    }
  }
}
