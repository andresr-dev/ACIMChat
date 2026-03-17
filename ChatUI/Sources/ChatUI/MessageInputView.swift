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
    
  var body: some View {
    HStack(alignment: .bottom) {
      TextField("Enter Message", text: $store.text, axis: .vertical)
//        .focused($focus)
        .multilineTextAlignment(.leading)
        .padding(10)
        .background {
          RoundedRectangle(cornerRadius: 25)
            .fill(Color(uiColor: .secondarySystemBackground))
        }
      
      Button {
        store.send(.sendMessageButtonPressed)
      } label: {
        Image(systemName: "arrow.up")
          .resizable()
          .scaledToFit()
          .foregroundStyle(.white)
          .fontWeight(.bold)
          .frame(height: 17)
          .frame(width: 40, height: 28)
          .background {
            Capsule()
              .fill(.blue)
          }
      }
    }
  }
}

#Preview {
  MessageInputView(
    store: Store(initialState: Chat.State()) {
      Chat()
    }
  )
}
