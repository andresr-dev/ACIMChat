
import ComposableArchitecture

@Reducer
public struct Chat {
  @ObservableState
  public struct State {
    public var messages: [Message]
    public var text: String
    public var isTyping = false
    
    public init(messages: [Message] = [], text: String = "") {
      self.messages = messages
      self.text = text
    }
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case sendMessageButtonPressed
    case aiResponse(Result<Message, Error>)
  }
  
  public init() { }
  
  @Dependency(\.aiClient) var aiClient
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .sendMessageButtonPressed:
        let text = state.text
        state.text = ""
        let message = Message(text: text, role: .user)
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
        
      case .binding:
        return .none
      }
    }
  }
}
