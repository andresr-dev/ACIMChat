//
//  ChatView.swift
//  ChatUI
//
//  Created by Andres Raigoza on 14/03/26.
//

import SwiftUI

struct ChatView: View {
  let messages: [Message]
  @State var text: String = ""
  
  var body: some View {
    VStack(spacing: 16) {
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(messages, content: MessageView.init)
        }
      }
      .defaultScrollAnchor(.bottom)
      
      MessageInputView(text: $text)
    }
    .padding()
  }
}

#Preview {
  ChatView(messages: Message.mock)
}
