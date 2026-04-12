
import ComposableArchitecture
import Chat
import SwiftUI

struct MessageView: View {
  let store: StoreOf<MessageFeature>
  
  var body: some View {
    VStack {
      if store.message.displayingDate {
        Text(store.message.date.formatted(date: .abbreviated, time: .omitted))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      HStack(alignment: .bottom) {
        if store.message.role == .ai {
          Image(.holySpirit)
            .resizable()
            .scaledToFit()
            .frame(width: 52, height: 52)
            .frame(width: 42, height: 42)
            .clipShape(Circle())
        }
        
        let alignment = store.message.role == .ai ? Alignment.leading : .trailing
        
        Text(store.message.text)
          .textSelection(.enabled)
          .foregroundStyle(store.message.role == .ai ? Color.primary : .white)
          .padding(12)
          .background(store.message.role == .ai ? Color(.secondarySystemBackground) : Color(.accent))
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
  MessageView(store: Store(initialState: MessageFeature.State(message: ChatModel.mock.messages[0])) {
    MessageFeature()
  })
}
