
import ComposableArchitecture
import Chat
import SwiftUI

struct MessageView: View {
  let store: StoreOf<MessageFeature>
  let imageSize: CGFloat = 42
  
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
            .frame(width: imageSize, height: imageSize)
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
      
      if store.message.role == .ai {
        Button {
          store.send(.speakButtonPressed)
        } label: {
          Group {
            store.isSpeaking ? Image(systemName: "stop.fill") : Image(systemName: "speaker.wave.2")
          }
          .padding(.vertical, 3)
          .padding(.leading, 16)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, imageSize)
      }
    }
  }
}

#Preview {
  MessageView(store: Store(initialState: MessageFeature.State(message: ChatModel.mock.messages[1])) {
    MessageFeature()
  })
}
