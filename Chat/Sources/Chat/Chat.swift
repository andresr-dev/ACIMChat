
import ComposableArchitecture
import Foundation

@Reducer
public struct Chat {
  @ObservableState
  public struct State: Equatable, Sendable {
    public var messages: [ChatMessage]
    public var text: String
    public var focusedField = false
    public var isTyping = false
    public var scrollPosition: UUID?
    public var isShowingSendButton: Bool {
      !text.isEmpty
    }
    
    public init(messages: [ChatMessage] = [], text: String = "") {
      self.messages = messages
      self.text = text
    }
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case onAppear
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
        return .none
        
      case .sendMessageButtonPressed:
        guard !state.text.isEmpty else { return .none }
        let text = state.text
        state.text = ""
        let lastScrolledID = state.messages.last?.id
        let message = ChatMessage(id: uuid(), text: text, role: .user, date: now)
        state.messages.append(message)
        state.isTyping = true
        if state.scrollPosition == lastScrolledID {
          state.scrollPosition = message.id
        }
        
        return .run { [aiClient, messages = state.messages] send in
          await send(.aiResponse(Result {
            try await aiClient.sendMessage(messages)
          }))
        }
        
      case let .aiResponse(result):
        state.isTyping = false
        
        switch result {
        case let .success(message):
          let lastScrolledID = state.messages.last?.id
          state.messages.append(message)
          if state.scrollPosition == lastScrolledID {
            state.scrollPosition = message.id
          }
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
