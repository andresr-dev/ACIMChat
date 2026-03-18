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
  @FocusState var focusedField: Bool
  let buttonWidth = 40.0
  let buttonHeight = 30.0
    
  var body: some View {
    ZStack(alignment: .bottom) {
      HStack {
        Spacer()
        
        if store.state.isShowingSendButton {
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
              .padding(.bottom, 6)
              .padding(.trailing, 8)
          }
        }
      }
      
      HStack {
        TextField("Enter Message", text: $store.text.sending(\.textChanged), axis: .vertical)
          .focused($focusedField)
          .multilineTextAlignment(.leading)
          .padding(10)
        
        Color.clear
          .frame(width: buttonWidth, height: buttonHeight)
      }
    }
    .glassEffect(.regular, in: .rect(cornerRadius: 24))
    .onAppear { store.send(.onAppear) }
    .bind($store.focusedField, to: $focusedField)
  }
}

#Preview {
  MessageInputView(
    store: Store(
      initialState: Chat.State(text: "")
    ) {
      Chat()
    }
  )
  .padding()
}
