import Foundation
import Speech

protocol VoiceRecognitionServiceProtocol {
    /// The current authorization status for speech recognition
    var authorizationStatus: SFSpeechRecognitionAuthorizationStatus { get }
    
    /// Request authorization for speech recognition
    func requestAuthorization() async
    
    /// Start recording and transcribing speech
    /// - Returns: An async stream of transcribed text
    func startRecording() -> AsyncStream<String>
    
    /// Stop the current recording session
    func stopRecording()
    
    /// Check if speech recognition is available on the device
    var isAvailable: Bool { get }
} 