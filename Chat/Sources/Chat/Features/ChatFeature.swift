
import ComposableArchitecture
import Foundation

@Reducer
public struct ChatFeature {
  @ObservableState
  public struct State: Equatable {
    public let id: UUID
    public var messages: IdentifiedArrayOf<MessageFeature.State>
    public var text: String
    public var focusedField = false
    public var isTyping = false
    public var scrollPosition: String?
    public let typingIndicatorID = "typing"
    public var isScrollAtBottom = false
    public var scrollToLastMessageTaskID: UUID?
    public var showingScrollToBottomButton = false
    public var aiResponseInProgressID: UUID?
    @Presents public var alert: AlertState<Action.Alert>?
    
    public var isShowingSendButton: Bool {
      text.count > 1
    }
    
    public init(id: UUID = UUID(), messages: [MessageFeature.State] = [], text: String = "") {
      self.id = id
      self.messages = IdentifiedArray(uniqueElements: messages)
      self.text = text
    }
  }
  
  public enum Action: BindableAction {
    case messages(IdentifiedActionOf<MessageFeature>)
    case binding(BindingAction<State>)
    case onAppear
    case sendMessageButtonPressed
    case aiResponse(Result<ChatMessage, Error>)
    case aiResponseFinished
    case alert(PresentationAction<Alert>)
    case delegate(Delegate)
    case scrollToBottomButtonPressed
    case scrollToBottom
    case scrollToTypingIndicator
    case scrollToLastMessage
    case isScrollAtBottomChanged(Bool)
    case textFieldHeightIncreased
    case updateShowingScrollToBottomButton(isShowing: Bool)
    case deleteMessage(id: UUID)
    
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
      case let .messages(.element(id: id, action: .delegate(delegateAction))):
        switch delegateAction {
        case .didStartSpeaking:
          let messagesSpeaking = state.messages.filter(\.isSpeaking)
          for messageID in messagesSpeaking.ids where messageID != id {
            state.messages[id: messageID]?.isSpeaking = false
          }
        }
        return .none
        
      case .messages:
        return .none
        
      case .onAppear:
        state.focusedField = state.messages.isEmpty
        return .none
        
      case .sendMessageButtonPressed:
        guard state.text.count > 1 else { return .none }
        let text = state.text
        var displayingDate = state.messages.isEmpty
        if let lastMessageDate = state.messages.last?.message.date {
          displayingDate = !Calendar.current.isDate(now, inSameDayAs: lastMessageDate)
        }
        let message = ChatMessage(id: uuid(), text: text, role: .user, date: now, displayingDate: displayingDate)
        state.messages.append(MessageFeature.State(message: message))
        state.isTyping = true
        state.text = ""
        state.focusedField = false
        let messages = Array(state.messages.map(\.message))
        
        return .run { [sendMessage, uuid] send in
          do {
            var message = ChatMessage(id: uuid(), role: .ai)
            
            for try await token in sendMessage(messages) {
              message.text += token
              await send(.aiResponse(.success(message)))
            }
          } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            await send(.deleteMessage(id: message.id))
          } catch _ as CancellationError {
            await send(.deleteMessage(id: message.id))
          } catch {
            await send(.aiResponse(.failure(error)))
          }
          await send(.aiResponseFinished)
        }
        
      case let .deleteMessage(id):
        state.messages.remove(id: id)
        return .none
        
      case let .aiResponse(result):
        state.isTyping = false
        
        switch result {
        case let .success(message):
          if state.messages.ids.contains(message.id) {
            state.messages[id: message.id]?.message = message
          } else {
            state.aiResponseInProgressID = message.id
            state.messages.append(MessageFeature.State(message: message))
          }
          return .none
        case .failure:
          state.alert = .error
          return .none
        }
        
      case .aiResponseFinished:
        state.aiResponseInProgressID = nil
        
        @Shared(.chats) var chats
        let messages = state.messages.map(\.message)
        if let lastMessage = messages.last, lastMessage.role == .ai {
          _ = $chats[id: state.id].withLock {
            $0?.messages.append(lastMessage)
          }
        }
        return .none
        
      case .scrollToBottomButtonPressed:
        return .send(.scrollToBottom)
        
      case .scrollToBottom:
        state.scrollPosition = nil
        
        return .run { [isTyping = state.isTyping] send in
          if isTyping {
            await send(.scrollToTypingIndicator)
          } else {
            await send(.scrollToLastMessage)
          }
        }
        
      case .scrollToLastMessage:
        state.scrollPosition = state.messages.last?.message.idString
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
        if let lastMessage = state.messages.last?.message,
           lastMessage.role == .user {
          return .send(.deleteMessage(id: lastMessage.id))
        }
        return .none
        
      case .binding, .alert, .delegate:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
    .forEach(\.messages, action: \.messages) {
      MessageFeature()
    }
    .onChange(of: \.messages.count) { oldValue, state in
      @Shared(.chats) var chats
      let messages = state.messages.map(\.message)
      if let lastMessage = messages.last, lastMessage.role == .user {
        _ = $chats[id: state.id].withLock {
          $0?.messages.append(lastMessage)
        }
      }
      return .send(.delegate(.chatUpdated(id: state.id)))
    }
  }
}

extension AlertState where Action == ChatFeature.Action.Alert {
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
