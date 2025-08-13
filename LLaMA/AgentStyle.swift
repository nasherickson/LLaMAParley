import Foundation
//
//  Nova.swift
//  Llamora
//
//  Created by Nash Erickson on 8/12/25.
//

let nova = Agent(
  name: "Nova", model: "llama3.1:8b-instruct-q4_K_M",
  systemPrompt: "Fast executor. Be concise, action-first.",
  wakeWord: "nova",
  voice: VoiceConfig(voiceId: "com.apple.voice.en-US.SiriFemale", rate: 0.55, pitch: 1.05)
)

let sage = Agent(
  name: "Sage", model: "llama3.1:8b-instruct-q4_K_M",
  systemPrompt: "Thoughtful analyst. Explain reasoning briefly, avoid fluff.",
  wakeWord: "sage",
  voice: VoiceConfig(voiceId: "com.apple.voice.en-US.Joelle", rate: 0.46, pitch: 0.98)
)
