//
//  Agent.swift
//  Llamora
//
//  Created by Nash Erickson on 8/12/25.
//

import Foundation

// Agent identity + behavior
struct Agent: Identifiable, Codable, Hashable {
    var id: UUID = .init()
    var name: String
    var model: String                    // e.g., "llama3.1:8b-instruct-q4_K_M"
    var systemPrompt: String             // persona instructions
    var wakeWord: String?                // optional: “nova”, “sage”, etc.
    var voice: VoiceConfig               // TTS persona
    var colorHex: String?                // UI accent
}

// Voice parameters you can tune live
struct VoiceConfig: Codable, Hashable {
    var ttsProvider: String = "apple"    // "apple", "eleven", "azure", …
    var voiceId: String = "com.apple.voice.en-US.Allison"
    var rate: Float = 0.48               // 0.0…1.0 mapped to AVSpeech
    var pitch: Float = 1.0               // 0.5…2.0
    var pauseAfterSentenceMs: Int = 120  // rhythm
}
