
import ComposableArchitecture
import Foundation

@Reducer
public struct Chat {
  @ObservableState
  public struct State: Equatable, Sendable {
    public var messages: [ChatMessage]
    public var text: String
    public var isShowingSendButton = false
    public var focusedField = false
    public var isTyping = false
    public var scrollPosition: UUID?
    
    public init(messages: [ChatMessage] = [], text: String = "") {
      self.messages = messages
      self.text = text
    }
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case onAppear
    case textChanged(String)
    case sendMessageButtonPressed
    case aiResponse(Result<ChatMessage, Error>)
  }
  
  public init() { }
  
  @Dependency(\.aiClient) var aiClient
  @Dependency(\.uuid) var uuid
  @Dependency(\.date.now) var now
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.focusedField = state.messages.isEmpty
        state.isShowingSendButton = !state.text.isEmpty
        return .none
        
      case let .textChanged(text):
        state.text = text
        return .none
        
      case .sendMessageButtonPressed:
        guard !state.text.isEmpty else { return .none }
        let text = state.text
        state.text = ""
        let message = ChatMessage(id: uuid(), text: text, role: .user, date: now)
        state.messages.append(message)
        state.isTyping = true
        state.scrollPosition = message.id
        
        return .run { [aiClient, messages = state.messages] send in
          await send(.aiResponse(Result {
            try await aiClient.sendMessage(messages)
          }))
        }
        
      case let .aiResponse(result):
        state.isTyping = false
        
        switch result {
        case let .success(message):
          state.messages.append(message)
          state.scrollPosition = message.id
          return .none
        case .failure:
          return .none
        }
        
      case .binding:
        return .none
      }
    }
    .onChange(of: \.text) { oldValue, state in
      state.isShowingSendButton = !state.text.isEmpty
      return .none
    }
  }
}
