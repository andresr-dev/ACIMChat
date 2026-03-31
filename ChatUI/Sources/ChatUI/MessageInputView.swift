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
  let textFieldPadding = 9.0
    
  var body: some View {
    ZStack(alignment: .bottom) {
      if store.isShowingSendButton {
        Button {
          store.send(.sendMessageButtonPressed)
        } label: {
          Image(systemName: "arrow.up")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: buttonWidth, height: buttonHeight)
            .background(Color(.accent))
            .clipShape(.capsule)
            .padding([.vertical, .trailing], textFieldPadding)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
      }
      
      HStack(spacing: 12) {
        TextField("Ingresa Mensaje", text: $store.text, axis: .vertical)
          .focused($focusedField)
          .multilineTextAlignment(.leading)
          .padding(.leading, 5)
        
        Color.clear
          .frame(width: buttonWidth, height: buttonHeight)
      }
      .padding(textFieldPadding)
    }
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
    .onAppear { store.send(.onAppear) }
    .bind($store.focusedField, to: $focusedField)
  }
}

#Preview {
  MessageInputView(
    store: Store(
      initialState: Chat.State(chat: Shared(value: .mock), text: "dfdf")
    ) {
      Chat()
    }
  )
  .padding()
}
