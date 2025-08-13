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
    private var acceptingAudio = false
    
    var onFinalizedUtterance: (String) -> Void = { _ in }

    // Helper: Recreate the recognition task with the current request.
    private func makeTask() {
        task?.cancel(); task = nil
        recognizer = SFSpeechRecognizer() // re-init in case locale/availability changed
        request.shouldReportPartialResults = true
        task = recognizer?.recognitionTask(with: request) { result, error in
            if let r = result {
                self.lastSpeechAt = Date()
                if r.isFinal {
                    self.onFinalizedUtterance(r.bestTranscription.formattedString)
                }
            }
            if let err = error {
                print("STT error: \(err.localizedDescription)")
                self.restart()
            }
        }
    }

    // Helper: Ensure audio engine is running.
    private func ensureAudioRunning() {
        if !audio.isRunning {
            audio.prepare()
            try? audio.start()
        }
    }

    func start() throws {
        let input = audio.inputNode
        let format = input.inputFormat(forBus: 0)

        request.shouldReportPartialResults = true
        makeTask()
        acceptingAudio = true

        input.installTap(onBus: 0, bufferSize: 2048, format: format) { buf, _ in
            guard self.acceptingAudio else { return }
            self.request.append(buf)
            self.detectSilenceAndFinalize(buf)
        }

        audio.prepare()
        lastSpeechAt = Date()
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
            acceptingAudio = false
            request.endAudio()
            // Re-arm for the next utterance: new request + new task.
            task?.cancel(); task = nil
            self.request = SFSpeechAudioBufferRecognitionRequest()
            self.request.shouldReportPartialResults = true
            self.makeTask()
            lastSpeechAt = Date()
            acceptingAudio = true
        }
    }

    private func restart() {
        task?.cancel(); task = nil
        makeTask()
        ensureAudioRunning()
    }

    func stop() {
        acceptingAudio = false
        audio.stop(); task?.cancel()
        request.endAudio()
        audio.inputNode.removeTap(onBus: 0)
    }
}
