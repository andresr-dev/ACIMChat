
import ComposableArchitecture

@Reducer
public struct Chat {
  @ObservableState
  public struct State: Equatable, Sendable {
    public var messages: [Message]
    public var text: String
    public var isTyping = false
    public var isShowingSendButton = false
    
    public init(messages: [Message] = [], text: String = "") {
      self.messages = messages
      self.text = text
    }
  }
  
  public enum Action {
    case textChanged(String)
    case sendMessageButtonPressed
    case aiResponse(Result<Message, Error>)
  }
  
  public init() { }
  
  @Dependency(\.aiClient) var aiClient
  @Dependency(\.uuid) var uuid
  @Dependency(\.date.now) var now
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .textChanged(text):
        state.text = text
        return .none
        
      case .sendMessageButtonPressed:
        guard !state.text.isEmpty else { return .none }
        let text = state.text
        state.text = ""
        let message = Message(id: uuid(), text: text, role: .user, date: now)
        state.messages.append(message)
        state.isTyping = true
        
        return .run { [aiClient] send in
          await send(.aiResponse(Result {
            try await aiClient.sendMessage(text)
          }))
        }
        
      case let .aiResponse(result):
        state.isTyping = false
        
        switch result {
        case let .success(message):
          state.messages.append(message)
          return .none
        case .failure:
          return .none
        }
      }
    }
    .onChange(of: \.text) { oldValue, state in
      state.isShowingSendButton = !state.text.isEmpty
      return .none
    }
  }
}
