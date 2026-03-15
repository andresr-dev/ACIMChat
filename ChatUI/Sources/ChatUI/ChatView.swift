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
    for i in 0..<32 {
      try? await Task.sleep(for: .seconds(2))
      let isAI = !i.isMultiple(of: 2)
      let message = Message(
        text: "This is a message in the chat, this is a message in the chat",
        isAI: isAI
      )
      messages.append(message)
    }
  }
}

public struct ChatView: View {
  @State var model = ChatModel()
  @State var position = ScrollPosition(idType: Message.ID.self)
  
  public init() { }
  
  public var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(model.messages) { message in
            MessageView(message: message)
          }
        }
        .padding([.horizontal])
        .scrollTargetLayout()
      }
      .defaultScrollAnchor(.bottom)
      .scrollPosition($position, anchor: .bottom)
      .onChange(of: model.messages) { _, newValue in
        if let id = newValue.last?.id {
          position.scrollTo(id: id, anchor: .bottom)
        }
      }
      .animation(.easeOut, value: model.messages)
      .animation(.easeOut, value: position)
      .padding(.top, 12)
      
      MessageInputView()
        .padding([.horizontal, .bottom])
        .padding(.top, 12)
        .background()
        .ignoresSafeArea()
    }
    .task {
      await model.getMessages()
    }
  }
}

#Preview {
  ChatView()
}
