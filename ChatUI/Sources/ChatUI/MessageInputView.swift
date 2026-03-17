//
//  MessageInputView.swift
//  ChatUI
//
//  Created by Andres Raigoza on 14/03/26.
//

import Chat
import ComposableArchitecture
import SwiftUI

struct MessageInputView: View {
  @Bindable var store: StoreOf<Chat>
  @FocusState var focus: Bool
  let buttonWidth = 40.0
  let buttonHeight = 28.0
    
  var body: some View {
    ZStack(alignment: .bottom) {
      HStack {
        Spacer()
        
        Button {
          store.send(.sendMessageButtonPressed)
        } label: {
          Image(systemName: "arrow.up")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .fontWeight(.bold)
            .frame(height: 17)
            .frame(width: buttonWidth, height: buttonHeight)
            .background(Color(.accent))
            .clipShape(.capsule)
        }
        .padding([.trailing, .bottom], 8)
      }
      
      HStack {
        TextField("Enter Message", text: $store.text, axis: .vertical)
          .focused($focus)
          .multilineTextAlignment(.leading)
          .padding(10)
        
        Color.clear
          .frame(width: buttonWidth, height: buttonHeight)
      }
    }
    .glassEffect(.regular, in: .rect(cornerRadius: 24))
    .onAppear {
      if store.messages.isEmpty {
        focus = true
      }
    }
  }
}

#Preview {
  MessageInputView(
    store: Store(
      initialState: Chat.State(text: " ddfdfddkdkdkdkdkdkdk ")
    ) {
      Chat()
    }
  )
  .padding()
}
