
import ComposableArchitecture
import Foundation

@Reducer
public struct ChatFeature {
  @ObservableState
  public struct State: Equatable {
    @Shared var chat: ChatModel
    public var messages: IdentifiedArrayOf<MessageFeature.State>
    public var text: String
    public var focusedField = false
    public var isTyping = false
    public var scrollPosition: ScrollPosition?
    public let typingIndicatorID = "typing"
    public var isScrollAtBottom = false
    public var scrollToLastMessageTaskID: UUID?
    public var showingScrollToBottomButton = false
    public var aiResponseInProgressID: UUID?
    @Presents public var alert: AlertState<Action.Alert>?
    
    public var isShowingSendButton: Bool {
      text.count > 1
    }
    
    public var isAIResponseInProgress: Bool {
      aiResponseInProgressID != nil
    }
    
    public enum ScrollPosition: Equatable {
      case ai(String)
      case user(String)
      case typing(String)
    }
    
    public init(chat: Shared<ChatModel>, text: String = "") {
      self._chat = chat
      let messages = chat.wrappedValue.messages.map(MessageFeature.State.init)
      self.messages = IdentifiedArray(uniqueElements: messages)
      self.text = text
    }
  }
  
  public enum Action: BindableAction {
    case messages(IdentifiedActionOf<MessageFeature>)
    case binding(BindingAction<State>)
    case onAppear
    case sendMessageButtonPressed
    case aiResponse(Result<String, Error>)
    case aiResponseFinished
    case alert(PresentationAction<Alert>)
    case delegate(Delegate)
    case scrollToBottomButtonPressed
    case scrollToBottom
    case scrollToTypingIndicator
    case scrollToLastAIMessage
    case scrollToLastUserMessage
    case isScrollAtBottomChanged(Bool)
    case textFieldHeightIncreased
    case updateShowingScrollToBottomButton(isShowing: Bool)
    case deleteMessage(id: UUID)
    case titleGenerated(String)
    
    @CasePathable
    public enum Alert: Equatable, Sendable {
      case confirm
    }
    
    @CasePathable
    public enum Delegate: Equatable {
      case moveChatToTop(id: ChatModel.ID)
    }
  }
  
  public init() { }
  
  @Dependency(\.aiClient) var aiClient
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
        case .stopOtherSpeakers:
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
        state.text = state.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard state.text.count > 1 else { return .none }
        let text = state.text
        var displayingDate = state.messages.isEmpty
        if let lastMessageDate = state.messages.last?.message.date {
          displayingDate = !Calendar.current.isDate(now, inSameDayAs: lastMessageDate)
        }
        let message = ChatMessage(id: uuid(), text: text, role: .user, date: now, displayingDate: displayingDate)
        _ = state.$chat.withLock {
          $0.messages.append(message)
        }
        state.messages.append(MessageFeature.State(message: message))
        state.isTyping = true
        state.text = ""
        state.focusedField = false
        let messages = Array(state.messages.map(\.message))
        
        return .run { [aiClient, chatID = state.chat.id] send in
          do {
            await send(.scrollToLastUserMessage)
            await send(.delegate(.moveChatToTop(id: chatID)))
            var response = ""
            for try await token in aiClient.sendMessage(messages) {
              response += token
              await send(.aiResponse(.success(response)))
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
        
      case let .deleteMessage(messageID):
        state.messages.remove(id: messageID)
        
        _ = state.$chat.withLock {
          $0.messages.remove(id: messageID)
        }
        return .none
        
      case let .aiResponse(result):
        state.isTyping = false
        switch result {
        case let .success(response):
          if state.aiResponseInProgressID == nil {
            state.aiResponseInProgressID = uuid()
          }
          guard let responseID = state.aiResponseInProgressID else { return .none }
          
          if state.messages.ids.contains(responseID) {
            state.messages[id: responseID]?.message.text = response
          } else {
            let aiMessage = ChatMessage(id: responseID, text: response, role: .ai, date: now)
            state.messages.append(MessageFeature.State(message: aiMessage))
          }
          return .none
        case .failure:
          state.alert = .error
          return .none
        }
        
      case .aiResponseFinished:
        let aiResponseID = state.aiResponseInProgressID
        state.aiResponseInProgressID = nil
        
        let messages = state.messages.map(\.message)
        let question = messages.last { $0.role == .user }
        let answer = messages.last { $0.id == aiResponseID && $0.role == .ai }
        if let answer {
          _ = state.$chat.withLock {
            $0.messages.append(answer)
          }
        }
        return .run { [aiClient, chatTitle = state.chat.title] send in
          guard let question = question?.text,
                let answer = answer?.text,
                chatTitle == nil else {
            return
          }
          let isQuestionValid = question.split(separator: " ").count >= 3
          let isAnswerValid = answer.split(separator: " ").count >= 20
          
          if isQuestionValid, isAnswerValid {
            let title = try? await aiClient.generateTitle(question, answer)
            if let title {
              await send(.titleGenerated(title))
            }
          }
        }
        
      case .scrollToBottomButtonPressed:
        return .send(.scrollToBottom)
        
      case .scrollToBottom:
        state.scrollPosition = nil
        
        return .run { [isTyping = state.isTyping] send in
          if isTyping {
            await send(.scrollToTypingIndicator)
          } else {
            await send(.scrollToLastAIMessage)
          }
        }
        
      case .scrollToLastAIMessage:
        guard let message = state.messages.last?.message, message.role == .ai else {
          return .none
        }
        state.scrollPosition = .ai(message.id.uuidString)
        return .none
        
      case .scrollToLastUserMessage:
        guard let message = state.messages.last?.message, message.role == .user else {
          return .none
        }
        state.scrollPosition = .user(message.id.uuidString)
        return .none
        
      case .scrollToTypingIndicator:
        state.scrollPosition = .typing(state.typingIndicatorID)
        return .none
        
      case let .isScrollAtBottomChanged(isScrollAtBottom):
        state.isScrollAtBottom = isScrollAtBottom
        
        return .run { [clock] send in
          if !isScrollAtBottom {
            try await withTaskCancellation(id: CancelID.scrollToBottomButton, cancelInFlight: true) {
              try await clock.sleep(for: .seconds(0.5))
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
        
      case let .titleGenerated(title):
        state.$chat.withLock {
          $0.title = title
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
