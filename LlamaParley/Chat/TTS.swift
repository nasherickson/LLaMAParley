import Foundation
import AVFoundation

@MainActor public class TTS {
    /// Clamp helper for readable bounds.
    private func clamped(_ value: Float, min lo: Float, max hi: Float) -> Float { max(lo, min(value, hi)) }

    private let synthesizer = AVSpeechSynthesizer()
    public var isSpeaking: Bool { synthesizer.isSpeaking }
    public func stop(immediately: Bool = false) {
        if immediately { synthesizer.stopSpeaking(at: .immediate) }
        else { synthesizer.stopSpeaking(at: .word) }
    }
    
    public func speak(_ text: String, with v: VoiceConfig) {
        let utterance = AVSpeechUtterance(string: text)
        
        var voice: AVSpeechSynthesisVoice?
        if let foundVoice = AVSpeechSynthesisVoice(identifier: v.voiceId) {
            voice = foundVoice
        } else {
            voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        utterance.voice = voice
        utterance.rate = clamped(v.rate, min: 0.4, max: 0.6)
        utterance.pitchMultiplier = clamped(v.pitch, min: 0.8, max: 1.2)
        
        synthesizer.speak(utterance)
    }
    
    public func speakSmooth(_ text: String, with v: VoiceConfig, preferMale: Bool = false) {
        // Derive a sensible language fallback from the requested voiceId if possible; else default to en-US.
        let voices = AVSpeechSynthesisVoice.speechVoices()
        func isMaleVoice(_ voice: AVSpeechSynthesisVoice) -> Bool {
            if #available(iOS 14.5, macOS 11.3, *) {
                return voice.gender == .male
            }
            let maleNames = ["Alex", "Fred", "Daniel", "Tom", "John", "Mike", "Paul", "Mark", "Peter"]
            return maleNames.contains(where: { voice.name.contains($0) })
        }
        func isPersonalVoice(_ voice: AVSpeechSynthesisVoice) -> Bool {
            // Heuristic: "Personal Voice" surfaces with telltale names/identifiers.
            let n = voice.name.lowercased()
            let id = voice.identifier.lowercased()
            return n.contains("personal voice") || id.contains("personalvoice") || id.contains("customvoice") || n.contains("personal")
        }
        let maleVoices = voices.filter { isMaleVoice($0) }
        let personalVoices = voices.filter { isPersonalVoice($0) }
        var derivedLanguage = "en-US"
        if let byId = AVSpeechSynthesisVoice(identifier: v.voiceId) {
            derivedLanguage = byId.language
        }

        var selectedVoice: AVSpeechSynthesisVoice?

        // 1) Exact identifier match (if valid)
        selectedVoice = AVSpeechSynthesisVoice(identifier: v.voiceId)

        // 2) Prefer Personal Voice if available (male + language match if requested)
        if selectedVoice == nil {
            // Try language-specific Personal Voice first
            var candidates = personalVoices.filter { $0.language == derivedLanguage }
            if preferMale { candidates = candidates.filter { isMaleVoice($0) } }
            selectedVoice = candidates.first

            // If none match language, try any Personal Voice (respect male preference if set)
            if selectedVoice == nil {
                var pv = personalVoices
                if preferMale { pv = pv.filter { isMaleVoice($0) } }
                selectedVoice = pv.first
            }
        }

        // 3) Gender + language preference (system voices)
        if selectedVoice == nil, preferMale {
            // Prefer an exact language + male match first
            selectedVoice = maleVoices.first(where: { $0.language == derivedLanguage })
            // If none found, just grab the first male voice in the list
            if selectedVoice == nil {
                selectedVoice = maleVoices.first
            }
        }

        // 4) Language-only fallback
        if selectedVoice == nil {
            selectedVoice = AVSpeechSynthesisVoice(language: derivedLanguage)
        }
        
        if let voice = selectedVoice {
            let genderString: String
            if #available(iOS 14.5, macOS 11.3, *) {
                let g = voice.gender
                switch g {
                case .male: genderString = "male"
                case .female: genderString = "female"
                case .unspecified: genderString = "unspecified"
                @unknown default: genderString = "unknown"
                }
            } else {
                genderString = "unknown"
            }
            print("Selected voice: name=\(voice.name), identifier=\(voice.identifier), gender=\(genderString)")
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice
        utterance.rate = clamped(v.rate, min: 0.3, max: 0.8)
        utterance.pitchMultiplier = clamped(v.pitch, min: 0.5, max: 2.0)
        
        synthesizer.speak(utterance)
    }
}
