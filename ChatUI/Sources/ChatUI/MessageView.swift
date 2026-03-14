
import SwiftUI

struct MessageView: View {
  let message: Message
  
  var body: some View {
    HStack(alignment: .bottom) {
      if message.isAI {
        Image(.holySpirit)
          .resizable()
          .scaledToFit()
          .frame(width: 54, height: 54)
          .frame(width: 44, height: 44)
          .clipShape(Circle())
      }
      
      let alignment = message.isAI ? Alignment.leading : .trailing
      
      Text(message.text)
        .fontWeight(.medium)
        .foregroundStyle(message.isAI ? Color.primary : .white)
        .padding(12)
        .background {
          RoundedRectangle(cornerRadius: 10)
            .fill(message.isAI ? Color(uiColor: .secondarySystemBackground) : .blue)
        }
        .containerRelativeFrame([.horizontal], alignment: alignment) { length, axis in
          length * 0.7
        }
        .frame(maxWidth: .infinity, alignment: alignment)
    }
  }
}

#Preview {
  MessageView(message: .mock[1])
}
