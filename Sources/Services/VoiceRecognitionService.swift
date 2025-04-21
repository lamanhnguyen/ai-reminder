import Foundation
import Speech
import Combine

@MainActor
final class VoiceRecognitionService: NSObject, VoiceRecognitionServiceProtocol {
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    private var continuation: AsyncStream<String>.Continuation?
    
    override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
    }
    
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }
    
    var isAvailable: Bool {
        speechRecognizer?.isAvailable ?? false
    }
    
    func requestAuthorization() async throws {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    continuation.resume()
                case .denied:
                    continuation.resume(throwing: VoiceRecognitionError.notAuthorized)
                case .restricted:
                    continuation.resume(throwing: VoiceRecognitionError.restricted)
                case .notDetermined:
                    continuation.resume(throwing: VoiceRecognitionError.notDetermined)
                @unknown default:
                    continuation.resume(throwing: VoiceRecognitionError.unknown)
                }
            }
        }
    }
    
    func startRecording() -> AsyncStream<String> {
        AsyncStream { continuation in
            self.continuation = continuation
            
            guard let recognizer = speechRecognizer, recognizer.isAvailable else {
                continuation.finish()
                return
            }
            
            audioEngine = AVAudioEngine()
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let audioEngine = audioEngine,
                  let recognitionRequest = recognitionRequest else {
                continuation.finish()
                return
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                
                let inputNode = audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    recognitionRequest.append(buffer)
                }
                
                audioEngine.prepare()
                try audioEngine.start()
                
                recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                    guard let self = self else { return }
                    
                    if let result = result {
                        continuation.yield(result.bestTranscription.formattedString)
                    }
                    
                    if error != nil || result?.isFinal == true {
                        self.stopRecording()
                        continuation.finish()
                    }
                }
            } catch {
                continuation.finish()
            }
        }
    }
    
    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        continuation?.finish()
        continuation = nil
    }
}

enum VoiceRecognitionError: LocalizedError {
    case notAuthorized
    case restricted
    case notDetermined
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition is not authorized"
        case .restricted:
            return "Speech recognition is restricted on this device"
        case .notDetermined:
            return "Speech recognition authorization has not been determined"
        case .unknown:
            return "An unknown error occurred with speech recognition"
        }
    }
} 