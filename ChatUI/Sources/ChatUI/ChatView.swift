//
//  ChatView.swift
//  ChatUI
//
//  Created by Andres Raigoza on 14/03/26.
//

import SwiftUI

@Observable
class ChatModel {
  var messages = [Message]()
  
  @MainActor
  func getMessages() async {
    for i in 0..<11 {
      try? await Task.sleep(for: .seconds(1))
      let isAI = !i.isMultiple(of: 2)
      let message = Message(
        text: "This is a message in the chat, this is a message in the chat",
        isAI: isAI
      )
      messages.append(message)
    }
  }
}

struct ChatView: View {
  @State var model = ChatModel()
  
  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(model.messages, content: MessageView.init)
        }
        .padding([.horizontal])
      }
      .defaultScrollAnchor(.bottom)
      .padding(.top, 12)
      
      MessageInputView()
        .padding([.horizontal, .bottom])
        .padding(.top, 12)
        .background()
        .ignoresSafeArea()
    }
    .animation(.easeOut, value: model.messages)
    .task {
      await model.getMessages()
    }
  }
}

#Preview {
  ChatView()
}
