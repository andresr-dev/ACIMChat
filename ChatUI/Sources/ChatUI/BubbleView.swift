
import SwiftUI

struct BubbleView: View {
  let message: String
  let isAI: Bool
  
  var body: some View {
    HStack(alignment: .bottom) {
      if !isAI {
        Spacer(minLength: 0)
      }
      
      if isAI {
        Image(.holySpirit)
          .resizable()
          .scaledToFit()
          .frame(width: 54, height: 54, alignment: .center)
          .frame(width: 44, height: 44)
          .clipShape(Circle())
      }
      
      Text(message)
        .foregroundStyle(isAI ? .primary : Color.white)
        .fontWeight(.medium)
        .padding(12)
        .background {
          RoundedRectangle(cornerRadius: 10)
            .fill(isAI ? Color(uiColor: .systemGray6) : .blue)
        }
      
      if isAI {
        Spacer(minLength: 0)
      }
    }
  }
}

#Preview {
  BubbleView(
    message: "This is a chat bubble with",
    isAI: true
  )
}
