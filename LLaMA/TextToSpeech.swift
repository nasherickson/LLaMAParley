import AVFoundation

struct SpeechCadence {
    let rate: Float           // 0.0 (slow) → 1.0 (fast). Default ~0.5
    let pitch: Float          // 0.5 (low) → 2.0 (high). Default 1.0
    let preDelay: TimeInterval  // Pause before speaking
    let postDelay: TimeInterval // Pause after speaking
    
    static let `default` = SpeechCadence(
        rate: AVSpeechUtteranceDefaultSpeechRate,
        pitch: 1.0,
        preDelay: 0.0,
        postDelay: 0.1
    )
    
    static var saved: SpeechCadence {
        let rate = UserDefaults.standard.float(forKey: "speechRate")
        let pitch = UserDefaults.standard.float(forKey: "speechPitch")
        let preDelay = UserDefaults.standard.double(forKey: "speechPreDelay")
        let postDelay = UserDefaults.standard.double(forKey: "speechPostDelay")
        
        return SpeechCadence(
            rate: rate > 0 ? rate : AVSpeechUtteranceDefaultSpeechRate,
            pitch: pitch > 0 ? pitch : 1.0,
            preDelay: preDelay,
            postDelay: postDelay
        )
    }
}

class TextToSpeech {
    static let shared = TextToSpeech()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String,
               language: String = "en-US",
               voiceIdentifier: String? = nil,
               cadence: SpeechCadence = .saved) {
        
        let utterance = AVSpeechUtterance(string: text)
        
        if let id = voiceIdentifier,
           let customVoice = AVSpeechSynthesisVoice(identifier: id) {
            utterance.voice = customVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: language)
        }
        
        utterance.rate = cadence.rate
        utterance.pitchMultiplier = cadence.pitch
        utterance.preUtteranceDelay = cadence.preDelay
        utterance.postUtteranceDelay = cadence.postDelay
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    func printAvailableVoices() {
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            print("\(voice.identifier): \(voice.name) [\(voice.language)]")
        }
    }
}
//
//  TextToSpeech.swift
//  Llamora
//
//  Created by Nash Erickson on 8/4/25.
//

