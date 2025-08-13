import AVFoundation
//
//  TTS.swift
//  Llamora
//
//  Created by Nash Erickson on 8/12/25.
//


final class TTS {
    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String, with v: VoiceConfig) {
        let utt = AVSpeechUtterance(string: text)

        // Prefer user-specified voice if valid, otherwise choose a friendlier fallback.
        let preferredIDs = [
            // Common friendly en-US voices; we try several identifiers to maximize compatibility
            "com.apple.ttsbundle.Samantha-compact",
            "com.apple.ttsbundle.Ava-compact",
            "com.apple.voice.compact.en-US.Samantha",
            "com.apple.voice.compact.en-US.Ava",
            "com.apple.voice.compact.en-US.Alex"
        ]

        let chosenVoice: AVSpeechSynthesisVoice? = {
            if let idVoice = AVSpeechSynthesisVoice(identifier: v.voiceId) { return idVoice }
            for id in preferredIDs {
                if let voice = AVSpeechSynthesisVoice(identifier: id) { return voice }
            }
            return AVSpeechSynthesisVoice(language: "en-US")
        }()

        guard let voice = chosenVoice else {
            print("Error: No available voice found. Listing installed voices:")
            for voice in AVSpeechSynthesisVoice.speechVoices() {
                print(" - id: \(voice.identifier), lang: \(voice.language)")
            }
            return
        }

        utt.voice = voice
        print("Using voice: id = \(voice.identifier), lang = \(voice.language)")

        // Calmer, less eerie defaults. If v.rate/pitch come in as 0, treat as neutral.
        let desiredRate = (v.rate == 0 ? 0.5 : v.rate).clamped(0.40, 0.60)
        utt.rate = AVSpeechUtteranceDefaultSpeechRate * desiredRate

        let desiredPitch = (v.pitch == 0 ? 1.0 : v.pitch).clamped(0.85, 1.15)
        utt.pitchMultiplier = desiredPitch

        // Small pauses help naturalness.
        utt.preUtteranceDelay = 0.02
        utt.postUtteranceDelay = 0.03

        synth.speak(utt)
    }

    static func logAvailableVoices() {
        for v in AVSpeechSynthesisVoice.speechVoices() {
            print("Voice => id: \(v.identifier) lang: \(v.language)")
        }
    }
}
extension Float { func clamped(_ a: Float,_ b: Float) -> Float { max(a, min(b, self)) } }
