//
//  MessageInputView.swift
//  ChatUI
//
//  Created by Andres Raigoza on 14/03/26.
//

import SwiftUI

struct MessageInputView: View {
  @State var text = ""
  @FocusState var focus: Bool
  
  var body: some View {
    HStack(alignment: .bottom) {
      TextField("Enter Message", text: $text, axis: .vertical)
        .focused($focus)
        .padding(14)
        .multilineTextAlignment(.leading)
        .background {
          RoundedRectangle(cornerRadius: 25)
            .fill(Color(uiColor: .secondarySystemBackground))
        }
        .onAppear {
          focus = true
        }
      
      Button {
        
      } label: {
        Image(systemName: "arrow.up")
          .resizable()
          .scaledToFit()
          .foregroundStyle(.white)
          .fontWeight(.bold)
          .frame(height: 18)
          .frame(width: 42, height: 32)
          .background {
            Capsule()
              .fill(.blue)
          }
      }
    }
  }
}

#Preview {
  MessageInputView(text: "skdfjsldkfjsldkfj lsdkfjsldkfjsdl dkfdkdkdkdkkdkdkdkdkd dkdkdkdkdkd dkdkdkdkdkd kdkdkdkdkdkd dkdkdkdkdkdkdkd")
    .padding()
}
