
import ComposableArchitecture
import Foundation

@Reducer
public struct Chat {
  @ObservableState
  public struct State: Equatable {
    public var chat: ChatModel
    public var text: String
    public var focusedField = false
    public var isTyping = false
    public var scrollPosition: UUID?
    @Presents public var alert: AlertState<Action.Alert>?
    
    public var isShowingSendButton: Bool {
      !text.isEmpty
    }
    
    public init(chat: ChatModel = ChatModel(messages: []), text: String = "") {
      self.chat = chat
      self.text = text
    }
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case onAppear
    case startScrollDelay
    case scrollToBottom
    case sendMessageButtonPressed
    case aiResponse(Result<ChatMessage, Error>)
    case alert(PresentationAction<Alert>)
    case delegate(Delegate)
    
    public enum Alert: Equatable, Sendable { }
    
    @CasePathable
    public enum Delegate: Equatable {
      case chatUpdated(ChatModel)
    }
  }
  
  public init() { }
  
  @Dependency(\.aiClient.sendMessage) var sendMessage
  @Dependency(\.uuid) var uuid
  @Dependency(\.date.now) var now
  @Dependency(\.continuousClock) var clock
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.focusedField = state.chat.messages.isEmpty
        return .send(.scrollToBottom)
        
      case .startScrollDelay:
        return .run { [clock] send in
          try await clock.sleep(for: .seconds(0.2))
          await send(.scrollToBottom, animation: .default)
        }
        
      case .scrollToBottom:
        state.scrollPosition = state.chat.messages.last?.id
        return .none
        
      case .sendMessageButtonPressed:
        guard !state.text.isEmpty else { return .none }
        let text = state.text
        var displayingDate = state.chat.messages.isEmpty
        if let lastMessageDate = state.chat.messages.last?.date {
          displayingDate = !Calendar.current.isDate(now, inSameDayAs: lastMessageDate)
        }
        let message = ChatMessage(id: uuid(), text: text, role: .user, date: now, displayingDate: displayingDate)
        state.chat.messages.append(message)
        state.isTyping = true
        state.text = ""
        let messages = Array(state.chat.messages.suffix(11))
        
        return .run { [sendMessage] send in
          await send(.startScrollDelay)
          await send(.aiResponse(Result {
            try await sendMessage(messages)
          }))
        }
        
      case let .aiResponse(result):
        state.isTyping = false
        
        switch result {
        case let .success(message):
          let lastScrolledID = state.chat.messages.last?.id
          state.chat.messages.append(message)
          return .run { [scrollPosition = state.scrollPosition] send in
            guard scrollPosition == lastScrolledID else { return }
            await send(.startScrollDelay)
          }
        case .failure:
          state.alert = .error
          return .none
        }
        
      case .binding, .alert, .delegate:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
    .onChange(of: \.chat) { oldValue, state in
        .send(.delegate(.chatUpdated(state.chat)))
    }
  }
}

extension AlertState where Action == Chat.Action.Alert {
  static let error = Self {
    TextState("Error")
  } message: {
    TextState("Por favor espera un momento e intenta de nuevo.")
  }
}
