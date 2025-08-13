import Foundation
import AVFoundation

public class TTS {
    private let synthesizer = AVSpeechSynthesizer()
    
    public func speak(_ text: String, with v: VoiceConfig) {
        let utterance = AVSpeechUtterance(string: text)
        
        var voice: AVSpeechSynthesisVoice?
        if let foundVoice = AVSpeechSynthesisVoice(identifier: v.voiceId) {
            voice = foundVoice
        } else {
            voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        utterance.voice = voice
        utterance.rate = max(0.4, min(v.rate, 0.6))
        utterance.pitchMultiplier = max(0.8, min(v.pitch, 1.2))
        
        synthesizer.speak(utterance)
    }
    
    public func speakSmooth(_ text: String, with v: VoiceConfig, preferMale: Bool = false) {
        let targetLanguage = v.voiceId ?? "en-US"
        let voices = AVSpeechSynthesisVoice.speechVoices()
        
        func isMaleVoice(_ voice: AVSpeechSynthesisVoice) -> Bool {
            if #available(iOS 14.5, macOS 11.3, *) {
                return voice.gender == .male
            }
            let maleNames = ["Alex", "Fred", "Daniel", "Tom", "John", "Mike", "Paul", "Mark", "Peter"]
            return maleNames.contains(where: { voice.name.contains($0) })
        }
        
        var selectedVoice: AVSpeechSynthesisVoice?
        
        if preferMale {
            selectedVoice = voices.first(where: { $0.language == targetLanguage && isMaleVoice($0) })
        }
        
        if selectedVoice == nil {
            let voiceId = v.voiceId
            selectedVoice = AVSpeechSynthesisVoice(identifier: voiceId)
            if selectedVoice == nil {
                selectedVoice = AVSpeechSynthesisVoice(language: targetLanguage)
            }
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
        utterance.rate = max(0.3, min(v.rate, 0.8))
        utterance.pitchMultiplier = max(0.5, min(v.pitch, 2.0))
        
        synthesizer.speak(utterance)
    }
}

