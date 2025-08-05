import SwiftUI

struct SpeechSettingsView: View {
    @AppStorage("speechRate") private var speechRate: Float = 0.45
    @AppStorage("speechPitch") private var speechPitch: Float = 1.0
    @AppStorage("speechPreDelay") private var speechPreDelay: Double = 0.1
    @AppStorage("speechPostDelay") private var speechPostDelay: Double = 0.2
    
    var body: some View {
        Form {
            Section(header: Text("Speech Cadence")) {
                VStack(alignment: .leading) {
                    Text("Rate: \(String(format: "%.2f", speechRate))")
                    Slider(value: $speechRate, in: 0.3...0.6, step: 0.01)
                }
                
                VStack(alignment: .leading) {
                    Text("Pitch: \(String(format: "%.2f", speechPitch))")
                    Slider(value: $speechPitch, in: 0.5...2.0, step: 0.05)
                }
                
                VStack(alignment: .leading) {
                    Text("Pre‑Utterance Delay: \(String(format: "%.2f", speechPreDelay))s")
                    Slider(value: $speechPreDelay, in: 0.0...0.5, step: 0.05)
                }
                
                VStack(alignment: .leading) {
                    Text("Post‑Utterance Delay: \(String(format: "%.2f", speechPostDelay))s")
                    Slider(value: $speechPostDelay, in: 0.0...0.5, step: 0.05)
                }
            }
            
            Section {
                Button("Test Voice") {
                    let cadence = SpeechCadence(
                        rate: speechRate,
                        pitch: speechPitch,
                        preDelay: speechPreDelay,
                        postDelay: speechPostDelay
                    )
                    TextToSpeech.shared.speak("This is a test of your custom cadence.", cadence: cadence)
                }
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}//
//  SpeechSettingsView.swift
//  Llamora
//
//  Created by Nash Erickson on 8/4/25.
//

