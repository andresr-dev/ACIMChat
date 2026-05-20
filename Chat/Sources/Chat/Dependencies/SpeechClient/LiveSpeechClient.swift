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

    return Self { text in
      try await synthesizer.speak(text: text)
    } stop: {
      await synthesizer.stop()
    }
  }
}

private actor SpeechSynthesizer {
  private var synthesizer: AVSpeechSynthesizer?
  private var engine: AVAudioEngine?
  private var playerNode: AVAudioPlayerNode?

  func speak(text: String) async throws {
    stop()

    #if os(iOS)
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, options: [.duckOthers])
    try session.setActive(true)
    #endif

    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: DeviceInfo.language)
    utterance.rate = 0.5
    utterance.pitchMultiplier = 1.0
    utterance.volume = 1.0

    let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
    continuation.onTermination = { [weak self] _ in
      Task { await self?.stop() }
    }

    let synth = AVSpeechSynthesizer()
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    let tracker = PlaybackTracker()
    engine.attach(player)
    self.synthesizer = synth
    self.engine = engine
    self.playerNode = player

    synth.write(utterance) { [weak engine, weak player] buffer in
      guard let pcm = buffer as? AVAudioPCMBuffer else { return }

      if pcm.frameLength == 0 {
        Task {
          if await tracker.synthesisFinished() {
            continuation.finish()
          }
        }
        return
      }

      guard let engine, let player else { return }
      if !engine.isRunning {
        engine.connect(player, to: engine.mainMixerNode, format: pcm.format)
        try? engine.start()
        player.play()
      }

      Task { await tracker.bufferScheduled() }
      player.scheduleBuffer(pcm, completionCallbackType: .dataPlayedBack) { _ in
        Task {
          if await tracker.bufferPlayed() {
            continuation.finish()
          }
        }
      }
    }

    for await _ in stream { }
    throw CancellationError()
  }

  func stop() {
    synthesizer?.stopSpeaking(at: .immediate)
    playerNode?.stop()
    engine?.stop()
    synthesizer = nil
    engine = nil
    playerNode = nil
  }
}

private actor PlaybackTracker {
  private var pending = 0
  private var synthesisComplete = false
  
  func bufferScheduled() {
    pending += 1
  }
  
  func bufferPlayed() -> Bool {
    pending -= 1
    return synthesisComplete && pending == 0
  }
  
  func synthesisFinished() -> Bool {
    synthesisComplete = true
    return pending == 0
  }
}
