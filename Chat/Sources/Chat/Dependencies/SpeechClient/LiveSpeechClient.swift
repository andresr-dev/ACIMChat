//
//  LiveSpeechClient.swift
//  Chat
//
//  Created by Andres Raigoza on 9/04/26.
//

import Dependencies
@preconcurrency import AVFoundation

extension SpeechClient: DependencyKey {
  static var liveValue: Self {
    let synthesizer = SpeechSynthesizer()
    
    return Self { text, language in
      try await synthesizer.speak(text: text, language: language)
    } stop: {
      await synthesizer.stop()
    }
  }
}

private actor SpeechSynthesizer {
  private var synthesizer: AVSpeechSynthesizer?
  private var delegate: Delegate?
  
  deinit {
    print("🙂 \(Self.self)/deinit")
  }
  
  func speak(text: String, language: String) async throws -> Bool {
    stop()
    let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
    delegate = Delegate {
      continuation.yield(false)
      continuation.finish()
    }
    continuation.onTermination = { [weak self] _ in
      Task { await self?.stop() }
    }
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: language)
    utterance.rate = 0.5
    utterance.pitchMultiplier = 1.0
    utterance.volume = 1.0

    synthesizer = AVSpeechSynthesizer()
    synthesizer?.delegate = delegate
    synthesizer?.speak(utterance)
    continuation.yield(true)

    for await isSpeaking in stream {
      return isSpeaking
    }
    throw CancellationError()
  }
  
  func stop() {
    synthesizer?.stopSpeaking(at: .immediate)
  }
}

private final class Delegate: NSObject, AVSpeechSynthesizerDelegate {
  let didStop: @Sendable () -> Void
  
  init(didStop: @escaping @Sendable () -> Void) {
    self.didStop = didStop
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    self.didStop()
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    self.didStop()
  }
}
