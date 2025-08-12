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
        utt.voice = AVSpeechSynthesisVoice(identifier: v.voiceId)
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utt.rate = AVSpeechUtteranceDefaultSpeechRate * v.rate.clamped(0.3, 0.8)
        utt.pitchMultiplier = v.pitch.clamped(0.5, 2.0)
        synth.speak(utt)
    }
}
extension Float { func clamped(_ a: Float,_ b: Float) -> Float { max(a, min(b, self)) } }
