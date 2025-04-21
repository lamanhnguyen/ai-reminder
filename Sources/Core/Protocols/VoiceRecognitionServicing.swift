import Foundation
import Speech

protocol VoiceRecognitionServicing {
    var isRecording: Bool { get }
    var transcribedText: String { get }
    
    func requestPermissions() async throws
    func startRecording() async throws
    func stopRecording() async throws
    func cancelRecording()
    
    var transcriptionPublisher: Published<String>.Publisher { get }
} 