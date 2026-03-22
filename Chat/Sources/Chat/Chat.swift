
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
    case scrollToBottom
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
        
      case .scrollToBottom:
        state.scrollPosition = state.messages.last?.id
        return .none
        
      case .sendMessageButtonPressed:
        guard !state.text.isEmpty else { return .none }
        let text = state.text
        let message = ChatMessage(id: uuid(), text: text, role: .user, date: now)
        state.messages.append(message)
        state.isTyping = true
        state.text = ""
        let messagesToSend = Array(state.messages.suffix(11))
        
        return .run { [aiClient] send in
          Task {
            await send(.aiResponse(Result {
              try await aiClient.sendMessage(messagesToSend)
            }))
          }
          Task {
            try await Task.sleep(for: .seconds(0.2))
            await send(.scrollToBottom, animation: .default)
          }
        }
        
      case let .aiResponse(result):
        state.isTyping = false
        
        switch result {
        case let .success(message):
          let lastScrolledID = state.messages.last?.id
          state.messages.append(message)
          return .run { [scrollPosition = state.scrollPosition] send in
            Task {
              guard scrollPosition == lastScrolledID else { return }
              try await Task.sleep(for: .seconds(0.2))
              await send(.scrollToBottom, animation: .default)
            }
          }
        case .failure:
          return .none
        }
        
      case .binding:
        return .none
      }
    }
  }
}
