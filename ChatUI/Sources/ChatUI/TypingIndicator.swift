//
//  TypingIndicator.swift
//  ChatUI
//
//  Created by Andres Raigoza on 17/03/26.
//

import SwiftUI

struct TypingIndicator: View {
  @State private var animating = false
  
  var body: some View {
    Image(systemName: "ellipsis")
      .symbolEffect(.variableColor, isActive: animating)
      .font(.title)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color(uiColor: .secondarySystemBackground))
      .clipShape(.capsule)
      .onAppear {
        withAnimation(.linear.repeatForever()) {
          animating = true
        }
      }
  }
}

#Preview {
  TypingIndicator()
}
