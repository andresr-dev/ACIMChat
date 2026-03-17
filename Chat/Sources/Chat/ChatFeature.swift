
import ComposableArchitecture

@Reducer
public struct ChatFeature {
  @ObservableState
  public struct State {
    public var messages = [Message]()
    public var text = ""
    
    public init() { }
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case sendMessageButtonPressed
    case aiResponse(Message)
  }
  
  public init() { }
  
  @Dependency(\.aiClient) var aiClient
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .sendMessageButtonPressed:
        // Validate text
        return .run { [text = state.text, aiClient] send in
          let message = try await aiClient.sendMessage(text)
          return await send(.aiResponse(message))
        }
      case let .aiResponse(message):
        state.messages.append(message)
        return .none
        
      case .binding:
        return .none
      }
    }
  }
}
