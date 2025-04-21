import Foundation
import Speech
import AVFoundation
import SwiftUI

protocol AudioInputNode {
    func installTap(onBus bus: AVAudioNodeBus, bufferSize: AVAudioFrameCount, format: AVAudioFormat?, block: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void)
    func removeTap(onBus bus: AVAudioNodeBus)
    var isInputAvailable: Bool { get }
}

extension AVAudioInputNode: AudioInputNode {
    var isInputAvailable: Bool {
        return true // AVAudioInputNode is always available in the simulator
    }
}

@available(macOS 10.15, *)
@MainActor
class VoiceRecognizer: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var errorMessage: String?
    @Published var isAuthorized = false
    @Published var audioLevel: Float = 0.0
    @Published var isSpeechDetected = false
    @Published var debugInfo: String = ""
    @Published var isListening = false
    
    // Make these properties internal for testing
    var audioEngine: AVAudioEngine!
    var speechRecognizer: SFSpeechRecognizer!
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    var inputNode: AVAudioInputNode?
    
    private let silenceThreshold: Float = 0.0002
    internal var retryCount = 0
    private let maxRetries = 3
    internal var noSpeechRetryCount = 0
    private let maxNoSpeechRetries = 3
    
    // Timeout properties
    private var silenceTimer: Timer?
    private let silenceTimeout: TimeInterval = 2.0 // Stop after 2 seconds of silence
    private var lastSpeechTime: Date?
    private var hasDetectedSpeech = false
    private var speechStartTime: Date?
    private let minimumSpeechDuration: TimeInterval = 0.3 // Minimum duration for valid speech
    private var consecutiveSpeechFrames = 0
    private let requiredConsecutiveFrames = 3 // Number of consecutive frames above threshold to consider speech
    
    // Add new property to track if we're waiting for final result
    private var waitingForFinalResult = false
    
    private var isShuttingDown = false
    
    init(audioEngine: AVAudioEngine) {
        super.init()
        self.audioEngine = audioEngine
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        requestPermissions()
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                        DispatchQueue.main.async {
                            if granted {
                                self?.isAuthorized = true
                            } else {
                                self?.isAuthorized = false
                                self?.errorMessage = "Microphone access denied"
                            }
                        }
                    }
                case .denied:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition access denied"
                case .restricted:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition not available"
                case .notDetermined:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition not yet authorized"
                @unknown default:
                    self?.isAuthorized = false
                    self?.errorMessage = "Unknown authorization status"
                }
            }
        }
    }
    
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        #if targetEnvironment(simulator)
        print("Running on simulator - audio input may be limited")
        #else
        guard audioSession.isInputAvailable else {
            throw NSError(domain: "VoiceRecognizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No audio input device available"])
        }
        #endif
        
        let inputNode = audioEngine.inputNode
        // AVAudioEngine.inputNode is already of type AVAudioInputNode, so no cast needed
        self.inputNode = inputNode
    }
    
    private func updateDebugInfo(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.debugInfo = message
            print("Debug: \(message)")
        }
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        lastSpeechTime = Date()
        consecutiveSpeechFrames = 0
        updateDebugInfo("Silence timer reset - Starting new timer with \(silenceTimeout)s timeout")
        
        // Create a weak reference to avoid retain cycles
        weak var weakSelf = self
        
        // Capture only what we need in the timer closure
        let currentSilenceTimeout = silenceTimeout
        
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let lastSpeech = self.lastSpeechTime {
                    let timeSinceLastSpeech = Date().timeIntervalSince(lastSpeech)
                    let timeRemaining = currentSilenceTimeout - timeSinceLastSpeech
                    
                    if timeSinceLastSpeech >= currentSilenceTimeout && self.hasDetectedSpeech && !self.waitingForFinalResult {
                        self.updateDebugInfo("Silence timeout reached (\(timeSinceLastSpeech)s of silence), stopping recording")
                        self.waitingForFinalResult = true
                        
                        // Reset UI state before ending audio
                        self.isSpeechDetected = false
                        self.audioLevel = 0.0
                        self.isListening = false
                        
                        self.recognitionRequest?.endAudio()
                    } else if self.hasDetectedSpeech {
                        self.updateDebugInfo("Time since last speech: \(String(format: "%.1f", timeSinceLastSpeech))s (timeout in \(String(format: "%.1f", timeRemaining))s)")
                    }
                }
            }
        }
    }
    
    internal func checkAudioLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        let channelData = buffer.floatChannelData?[0]
        let frameLength = UInt32(buffer.frameLength)
        
        var sum: Float = 0.0
        if let channelData = channelData {
            for i in 0..<Int(frameLength) {
                sum += abs(channelData[i])
            }
        }
        let level = sum / Float(frameLength)
        
        Task { @MainActor in
            self.audioLevel = level
            let isAboveThreshold = level > self.silenceThreshold
            let wasSpeechDetected = self.isSpeechDetected
            
            if isAboveThreshold {
                self.consecutiveSpeechFrames += 1
                if self.consecutiveSpeechFrames >= self.requiredConsecutiveFrames {
                    if !wasSpeechDetected {
                        self.updateDebugInfo("Speech detected! Audio level: \(level) (sustained for \(self.consecutiveSpeechFrames) frames)")
                        self.speechStartTime = Date()
                    }
                    self.isSpeechDetected = true
                    self.hasDetectedSpeech = true
                    self.lastSpeechTime = Date()
                }
            } else {
                self.consecutiveSpeechFrames = 0
                if wasSpeechDetected {
                    if let startTime = self.speechStartTime,
                       Date().timeIntervalSince(startTime) >= self.minimumSpeechDuration {
                        self.updateDebugInfo("Speech ended. Audio level: \(level) (duration: \(String(format: "%.1f", Date().timeIntervalSince(startTime)))s)")
                    } else {
                        self.updateDebugInfo("Speech too short, ignoring. Audio level: \(level)")
                    }
                    self.isSpeechDetected = false
                }
            }
            
            if self.hasDetectedSpeech {
                self.updateDebugInfo("Audio level: \(level) (\(isAboveThreshold ? "above" : "below") threshold, consecutive frames: \(self.consecutiveSpeechFrames))")
            }
        }
        
        return level
    }
    
    internal func handleSpeechRecognitionError(_ error: Error) {
        let nsError = error as NSError
        let errorDescription = error.localizedDescription
        
        updateDebugInfo("Handling error: \(errorDescription)")
        
        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1101 {
            if retryCount < maxRetries {
                retryCount += 1
                updateDebugInfo("Retrying speech recognition (attempt \(retryCount)/\(maxRetries))")
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1))
                    do {
                        try self.startRecording()
                    } catch {
                        self.errorMessage = "Failed to start recording: \(error.localizedDescription)"
                        self.updateDebugInfo("Failed to start recording: \(error.localizedDescription)")
                    }
                }
            } else {
                errorMessage = "Unable to access speech recognition service. Please check your internet connection and try again."
                stopRecording()
            }
        } else if errorDescription.contains("No speech detected") {
            if noSpeechRetryCount < maxNoSpeechRetries {
                noSpeechRetryCount += 1
                updateDebugInfo("No speech detected, retrying (attempt \(noSpeechRetryCount)/\(maxNoSpeechRetries))")
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.5))
                    do {
                        try self.startRecording()
                    } catch {
                        self.errorMessage = "Failed to start recording: \(error.localizedDescription)"
                        self.updateDebugInfo("Failed to start recording: \(error.localizedDescription)")
                    }
                }
            } else {
                errorMessage = "No speech detected. Please speak clearly into the microphone."
                stopRecording()
            }
        } else {
            errorMessage = "Recognition error: \(errorDescription)"
            stopRecording()
        }
    }
    
    func startRecording() throws {
        guard !isRecording else { return }
        guard isAuthorized else {
            throw VoiceRecognizerError.notAuthorized
        }
        
        // Setup audio session when recording starts
        try setupAudioSession()
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceRecognizerError.unableToCreateRecognitionRequest
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.stopRecording()
                self.recognitionTask = nil
            }
        }
        
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            _ = self.checkAudioLevel(buffer)
            recognitionRequest.append(buffer)
        }
        
        try audioEngine.start()
        isRecording = true
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isRecording = false
        
        // Deactivate audio session when done recording
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    func shutdown() {
        guard !isShuttingDown else { return }
        isShuttingDown = true
        stopRecording()
    }
}

enum VoiceRecognizerError: Error {
    case notAuthorized
    case unableToCreateRecognitionRequest
    case invalidInputNode
} 
