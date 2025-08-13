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

    // Configure AVAudioSession for iOS/Catalyst so input format is valid
    private func configureSessionIfNeeded() throws {
        #if os(iOS) || targetEnvironment(macCatalyst)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setPreferredSampleRate(44100)
        try session.setPreferredIOBufferDuration(0.02)
        try session.setActive(true, options: [])
        #endif
    }

    func start() throws {
        let input = audio.inputNode

        // Ensure the session is configured/active on iOS/Catalyst BEFORE querying formats or installing the tap
        try configureSessionIfNeeded()

        request.shouldReportPartialResults = true
        makeTask()
        acceptingAudio = true

        #if os(iOS) || targetEnvironment(macCatalyst)
        // On iOS/Catalyst, use the node's OUTPUT format (valid, non-zero rate/channels)
        var tapFormat = input.outputFormat(forBus: 0)
        if tapFormat.sampleRate == 0 || tapFormat.channelCount == 0 {
            // Fallback: let Core Audio choose the hardware format
            tapFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) ?? input.outputFormat(forBus: 0)
        }
        input.installTap(onBus: 0, bufferSize: 2048, format: tapFormat) { buf, _ in
            guard self.acceptingAudio else { return }
            // Ignore zero-length buffers which can appear during interruptions
            if buf.frameLength == 0 { return }
            self.request.append(buf)
            self.detectSilenceAndFinalize(buf)
        }
        #else
        // On macOS, passing nil lets the engine pick the correct hardware format safely
        input.installTap(onBus: 0, bufferSize: 2048, format: nil) { buf, _ in
            guard self.acceptingAudio else { return }
            if buf.frameLength == 0 { return }
            self.request.append(buf)
            self.detectSilenceAndFinalize(buf)
        }
        #endif

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
