//
//  ChatView.swift
//  ChatUI
//
//  Created by Andres Raigoza on 14/03/26.
//

import Chat
import ComposableArchitecture
import SwiftUI

public struct ChatView: View {
  @Bindable var store: StoreOf<ChatFeature>
  private let rowInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
  @State private var contentHeight: CGFloat = 10
  @State private var lastUserMessageHeight: CGFloat = 10
  @State private var lastAIMessageHeight: CGFloat = 10
  @State private var inputHeight: CGFloat = 10
  
  var aiMessageBackgroundHeight: CGFloat {
    let visibleContentHeight = max(contentHeight - lastUserMessageHeight - inputHeight - 92, 10)
    if store.isAIResponseInProgress || store.isTyping {
      return visibleContentHeight
    } else {
      return min(visibleContentHeight, lastAIMessageHeight)
    }
  }
  
  func isLastUserMessage(_ message: ChatMessage) -> Bool {
    message.role == .user && store.messages.last?.message == message
  }
  
  func isLastAIMessage(_ message: ChatMessage) -> Bool {
    message.role == .ai && store.messages.last?.message == message
  }
  
  public init(store: StoreOf<ChatFeature>) {
    self.store = store
  }
  
  public var body: some View {
    VStack {
      ScrollViewReader { proxy in
        List {
          ForEach(store.scope(state: \.messages, action: \.messages)) { messageStore in

            ZStack(alignment: .topLeading) {
              if isLastAIMessage(messageStore.message) && !store.focusedField {
                Color.clear
                  .frame(height: aiMessageBackgroundHeight)
              }
              MessageView(
                store: messageStore,
                isAIResponseInProgress: store.aiResponseInProgressID == messageStore.id
              )
              .onGeometryChange(for: CGFloat.self, of: { proxy in
                proxy.size.height
              }, action: { newValue in
                if isLastUserMessage(messageStore.message) {
                  lastUserMessageHeight = newValue
                } else if isLastAIMessage(messageStore.message) {
                  lastAIMessageHeight = newValue
                }
              })
            }
            .id(messageStore.message.id.uuidString)
            .listRowSeparator(.hidden)
            .listRowInsets(rowInsets)
          }
          
          if store.isTyping {
            ZStack(alignment: .topLeading) {
              if !store.focusedField {
                Color.clear
                  .frame(height: aiMessageBackgroundHeight)
              }
              TypingIndicator()
            }
            .id(store.typingIndicatorID)
            .listRowSeparator(.hidden)
            .listRowInsets(rowInsets)
          }
        }
        .listStyle(.plain)
        .listRowSpacing(12)
        .scrollDismissesKeyboard(.interactively)
        .onScrollGeometryChange(for: Bool.self, of: { geo in
          let bottomOffsetY = geo.contentOffset.y + geo.visibleRect.height
          let contentHeight = geo.contentSize.height
          return bottomOffsetY > contentHeight - 20
        }, action: { wasScrollAtBottom, isScrollAtBottom in
          store.send(.isScrollAtBottomChanged(isScrollAtBottom))
        })
        .onScrollGeometryChange(for: CGFloat.self, of: { geo in
          geo.visibleRect.height
        }, action: { _, newValue in
          if newValue > contentHeight {
            contentHeight = newValue
          }
        })
        .task(id: store.scrollToLastMessageTaskID) {
          proxy.scrollTo(store.messages.last?.message.id.uuidString, anchor: .bottom)
        }
        .onChange(of: store.scrollPosition) { _, position in
          guard let position else { return }
          withAnimation {
            switch position {
            case let .ai(id):
              proxy.scrollTo(id, anchor: .bottom)
            case let .user(id):
              proxy.scrollTo(id, anchor: .top)
            case let .typing(id):
              proxy.scrollTo(id, anchor: .bottom)
            }
          }
        }
      }
      
      MessageInputView(store: store)
        .padding([.horizontal, .bottom])
        .padding(.top, 6)
        .background {
          Color(.systemBackground)
            .ignoresSafeArea()
        }
        .onGeometryChange(for: CGFloat.self, of: { proxy in
          proxy.size.height
        }, action: { newValue in
          inputHeight = newValue
        })
        .overlay(alignment: .topTrailing) {
          if store.showingScrollToBottomButton {
            Button {
              store.send(.scrollToBottomButtonPressed)
            } label: {
              Image(systemName: "chevron.down")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 34, height: 34)
            }
            .tint(.primary)
            .glassEffect(.regular.interactive(), in: .circle)
            .padding(.trailing, 10)
            .offset(y: -60)
            .transition(.asymmetric(
              insertion: .opacity.animation(.default),
              removal: .identity
            ))
          }
        }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        HStack(spacing: 12) {
          Image(.holySpirit)
            .resizable()
            .scaledToFit()
            .frame(width: 52, height: 52)
            .frame(width: 42, height: 42)
            .clipShape(Circle())
          
          Text("UCDM")
        }
      }
    }
    .alert($store.scope(state: \.alert, action: \.alert))
  }
}

#Preview("Success") {
  NavigationStack {
    ChatView(
      store: Store(
        initialState: ChatFeature.State(text: "Hello")
      ) {
        ChatFeature()
//          ._printChanges()
      }
    )
  }
}

#Preview("Failure") {
  NavigationStack {
    ChatView(
      store: Store(
        initialState: ChatFeature.State(text: "Hello")
      ) {
        ChatFeature()
      } withDependencies: {
        $0.aiClient = .mock(.failure)
      }
    )
  }
}
