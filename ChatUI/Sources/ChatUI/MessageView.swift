
import Chat
import SwiftUI

struct MessageView: View {
  let message: ChatMessage
  
  var body: some View {
    VStack {
      if message.displayingDate {
        Text(message.date.formatted(date: .abbreviated, time: .omitted))
          .font(.caption)
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
      }
      
      HStack(alignment: .bottom) {
        if message.role == .ai {
          Image(.holySpirit)
            .resizable()
            .scaledToFit()
            .frame(width: 52, height: 52)
            .frame(width: 42, height: 42)
            .clipShape(Circle())
        }
        
        let alignment = message.role == .ai ? Alignment.leading : .trailing
        
        Text(message.text)
          .foregroundStyle(message.role == .ai ? Color.primary : .white)
          .padding(12)
          .background(message.role == .ai ? Color(.secondarySystemBackground) : Color(.accent))
          .clipShape(.rect(cornerRadius: 12))
          .containerRelativeFrame([.horizontal], alignment: alignment) { length, axis in
            length * 0.7
          }
          .frame(maxWidth: .infinity, alignment: alignment)
      }
    }
  }
}

#Preview {
  MessageView(message: .mockUserMessage)
}
