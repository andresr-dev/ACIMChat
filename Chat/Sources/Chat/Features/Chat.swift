
import ComposableArchitecture
import Foundation

@Reducer
public struct Chat {
  @ObservableState
  public struct State: Equatable, Sendable {
    @Shared public var chat: ChatModel
    public var text: String
    public var focusedField = false
    public var isTyping = false
    public var scrollPosition: String?
    public let typingIndicatorID = "typing"
    public var isScrollAtBottom = false
    public var scrollToLastMessageTaskID: UUID?
    public var showingScrollToBottomButton = false
    @Presents public var alert: AlertState<Action.Alert>?
    var userMessage: ChatMessage?
    
    public var isShowingSendButton: Bool {
      !text.isEmpty
    }
    
    public init(chat: Shared<ChatModel>, text: String = "") {
      self._chat = chat
      self.text = text
    }
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case onAppear
    case sendMessageButtonPressed
    case aiResponse(Result<ChatMessage, Error>)
    case alert(PresentationAction<Alert>)
    case delegate(Delegate)
    case scrollToBottomButtonPressed
    case scrollToBottom
    case scrollToTypingIndicator
    case scrollToLastMessage
    case isScrollAtBottomChanged(Bool)
    case textFieldHeightIncreased
    case updateShowingScrollToBottomButton(isShowing: Bool)
    
    @CasePathable
    public enum Alert: Equatable, Sendable {
      case confirm
    }
    
    @CasePathable
    public enum Delegate: Equatable {
      case chatUpdated(id: ChatModel.ID)
    }
  }
  
  public init() { }
  
  @Dependency(\.aiClient.sendMessage) var sendMessage
  @Dependency(\.uuid) var uuid
  @Dependency(\.date.now) var now
  @Dependency(\.continuousClock) var clock
  enum CancelID { case scrollToBottomButton }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
      .onChange(of: \.focusedField) { oldValue, state in
        guard state.focusedField && state.isScrollAtBottom else { return .none }
        return .run { send in
          await send(.scrollToBottom)
        }
      }
    
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.focusedField = state.chat.messages.isEmpty
        return .none
        
      case .sendMessageButtonPressed:
        guard !state.text.isEmpty else { return .none }
        let text = state.text
        var displayingDate = state.chat.messages.isEmpty
        if let lastMessageDate = state.chat.messages.last?.date {
          displayingDate = !Calendar.current.isDate(now, inSameDayAs: lastMessageDate)
        }
        let message = ChatMessage(id: uuid(), text: text, role: .user, date: now, displayingDate: displayingDate)
        _ = state.$chat.withLock {
          $0.messages.append(message)
        }
        state.isTyping = true
        state.text = ""
        let messages = Array(state.chat.messages.suffix(11))
        
        return .run { [chatID = state.chat.id, sendMessage] send in
          await send(.scrollToBottom)
          await send(.aiResponse(Result {
            func deleteMessage(_ message: ChatMessage) {
              @Shared(.chats) var chats
              _ = $chats[id: chatID].withLock {
                $0?.messages.remove(message)
              }
            }
            do {
              return try await sendMessage(messages)
            } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
              deleteMessage(message)
              throw error
            } catch let error as CancellationError {
              deleteMessage(message)
              throw error
            } catch { throw error }
          }))
        }
        
      case let .aiResponse(result):
        state.isTyping = false
        
        switch result {
        case let .success(message):
          _ = state.$chat.withLock {
            $0.messages.append(message)
          }
          return .run { send in
            await send(.scrollToBottom)
          }
        case .failure:
          state.alert = .error
          return .none
        }
        
      case .scrollToBottomButtonPressed:
        return .send(.scrollToBottom)
        
      case .scrollToBottom:
        state.showingScrollToBottomButton = false
        state.scrollPosition = nil
        
        return .run { [isTyping = state.isTyping] send in
          if isTyping {
            await send(.scrollToTypingIndicator)
          } else {
            await send(.scrollToLastMessage)
          }
        }
        
      case .scrollToLastMessage:
        state.scrollPosition = state.chat.messages.last?.idString
        return .none
        
      case .scrollToTypingIndicator:
        state.scrollPosition = state.typingIndicatorID
        return .none
        
      case let .isScrollAtBottomChanged(isScrollAtBottom):
        state.isScrollAtBottom = isScrollAtBottom
        
        return .run { [clock] send in
          if !isScrollAtBottom {
            try await withTaskCancellation(id: CancelID.scrollToBottomButton, cancelInFlight: true) {
              try await clock.sleep(for: .seconds(1))
              await send(.updateShowingScrollToBottomButton(isShowing: true))
            }
          } else {
            Task.cancel(id: CancelID.scrollToBottomButton)
            await send(.updateShowingScrollToBottomButton(isShowing: false))
          }
        }
        
      case .textFieldHeightIncreased:
        guard state.isScrollAtBottom else { return .none }
        state.scrollToLastMessageTaskID = uuid()
        return .none
        
      case let .updateShowingScrollToBottomButton(isShowing):
        state.showingScrollToBottomButton = isShowing
        return .none
        
      case .alert(.presented(.confirm)):
        if let lastMessage = state.chat.messages.last, lastMessage.role == .user {
          _ = state.$chat.withLock {
            $0.messages.remove(lastMessage)
          }
        }
        return .none
        
      case .binding, .alert, .delegate:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
    .onChange(of: \.chat) { oldValue, state in
        .send(.delegate(.chatUpdated(id: state.chat.id)))
    }
  }
}

extension AlertState where Action == Chat.Action.Alert {
  static let error = Self {
    TextState("Error")
  } actions: {
    ButtonState(role: .cancel, action: .confirm) {
      TextState("OK")
    }
  } message: {
    TextState("Por favor espera un momento e intenta de nuevo.")
  }
}
