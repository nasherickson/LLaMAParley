import AVFoundation
import Speech
import Accelerate
//
//  AutoDictationCoordinator.swift
//  Llamora
//
//  Created by Nash Erickson on 8/12/25.
//


final class AutoDictationCoordinator {
    private let audio = AVAudioEngine()
    private var request = SFSpeechAudioBufferRecognitionRequest()
    private var recognizer = SFSpeechRecognizer()
    private var task: SFSpeechRecognitionTask?
    private var lastSpeechAt = Date()
    private let silenceMs = 900  // tweakable
    
    var onFinalizedUtterance: (String) -> Void = { _ in }

    func start() throws {
        let input = audio.inputNode
        let format = input.inputFormat(forBus: 0)

        request.shouldReportPartialResults = true

        task = recognizer?.recognitionTask(with: request) { result, error in
            if let r = result {
                self.lastSpeechAt = Date()
                if r.isFinal {
                    self.onFinalizedUtterance(r.bestTranscription.formattedString)
                }
            }
            if error != nil { self.restart() }
        }

        input.installTap(onBus: 0, bufferSize: 2048, format: format) { buf, _ in
            self.request.append(buf)
            self.detectSilenceAndFinalize(buf)
        }

        audio.prepare()
        try audio.start()
    }

    private func detectSilenceAndFinalize(_ buf: AVAudioPCMBuffer) {
        // quick RMS VAD
        guard let ch = buf.floatChannelData?.pointee else { return }
        let n = Int(buf.frameLength)
        var sum: Float = 0
        vDSP_measqv(ch, 1, &sum, vDSP_Length(n))
        let rms = sqrt(sum)
        if rms < 0.001, Date().timeIntervalSince(lastSpeechAt) > Double(silenceMs) / 1000.0 {
            // Ask Apple’s STT to flush — if no final already, synthesize one from bestPartial
            request.endAudio()
            // Re-arm for the next utterance
            self.request = SFSpeechAudioBufferRecognitionRequest()
            self.request.shouldReportPartialResults = true
            self.restart()
        }
    }

    private func restart() {
        task?.cancel(); task = nil
        // You’d recreate the recognitionTask with the new request here (omitted for brevity)
    }

    func stop() {
        audio.stop(); task?.cancel()
        audio.inputNode.removeTap(onBus: 0)
    }
}
