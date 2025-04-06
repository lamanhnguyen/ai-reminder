import XCTest
import Speech
import AVFoundation
@testable import VoiceReminders

// Mock AVAudioEngine for testing
class MockAudioEngine: AVAudioEngine {
    let mockInputNode = MockAudioInputNode()
    override var inputNode: AVAudioInputNode {
        return mockInputNode
    }
    
    var isRunning = false
    
    override func start() throws {
        isRunning = true
    }
    
    override func stop() {
        isRunning = false
    }
}

// Mock AudioInputNode for testing
class MockAudioInputNode: AVAudioInputNode {
    var tapBlock: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?
    var isInputAvailable = true
    
    override func installTap(onBus bus: AVAudioNodeBus, bufferSize: AVAudioFrameCount, format: AVAudioFormat?, block: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) {
        tapBlock = block
    }
    
    override func removeTap(onBus bus: AVAudioNodeBus) {
        tapBlock = nil
    }
    
    override func outputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat {
        return AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)!
    }
}

// Mock SFSpeechRecognizer for testing
class MockSpeechRecognizer: SFSpeechRecognizer {
    private var _isAvailable = true
    var recognitionTask: MockSpeechRecognitionTask?
    var mockResult: SFSpeechRecognitionResult?
    var mockError: Error?
    
    override var isAvailable: Bool {
        get { return _isAvailable }
    }
    
    override func recognitionTask(with request: SFSpeechRecognitionRequest, resultHandler: @escaping (SFSpeechRecognitionResult?, Error?) -> Void) -> SFSpeechRecognitionTask {
        let task = MockSpeechRecognitionTask()
        task.completionHandler = resultHandler
        recognitionTask = task
        return task
    }
    
    func simulateResult(_ result: SFSpeechRecognitionResult) {
        mockResult = result
        // Simulate recognition task completion
        let task = MockSpeechRecognitionTask()
        task.completionHandler?(result, nil)
    }
    
    func simulateError(_ error: Error) {
        mockError = error
        // Simulate recognition task error
        let task = MockSpeechRecognitionTask()
        task.completionHandler?(nil, error)
    }
}

// Mock SpeechRecognitionTask for testing
class MockSpeechRecognitionTask: SFSpeechRecognitionTask {
    var completionHandler: ((SFSpeechRecognitionResult?, Error?) -> Void)?
    private var _isCancelled = false
    
    override var isCancelled: Bool {
        get { return _isCancelled }
    }
    
    override func cancel() {
        _isCancelled = true
    }
}

// Mock SpeechRecognitionResult for testing
class MockSpeechRecognitionResult: SFSpeechRecognitionResult {
    private let _transcription: SFTranscription
    private let _isFinal: Bool
    
    init(transcription: SFTranscription, isFinal: Bool) {
        _transcription = transcription
        _isFinal = isFinal
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var bestTranscription: SFTranscription {
        return _transcription
    }
    
    override var isFinal: Bool {
        return _isFinal
    }
}

// Mock Transcription for testing
class MockTranscription: SFTranscription {
    private let _formattedString: String
    
    init(formattedString: String) {
        _formattedString = formattedString
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var formattedString: String {
        return _formattedString
    }
}

class VoiceRecognizerTests: XCTestCase {
    var voiceRecognizer: VoiceRecognizer!
    var mockAudioEngine: MockAudioEngine!
    var mockSpeechRecognizer: MockSpeechRecognizer!
    
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        mockSpeechRecognizer = MockSpeechRecognizer()
        voiceRecognizer = VoiceRecognizer(audioEngine: mockAudioEngine)
        
        // Inject mock objects
        voiceRecognizer.speechRecognizer = mockSpeechRecognizer
        voiceRecognizer.isAuthorized = true
    }
    
    override func tearDown() {
        voiceRecognizer = nil
        mockAudioEngine = nil
        mockSpeechRecognizer = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertFalse(voiceRecognizer.isRecording)
        XCTAssertFalse(voiceRecognizer.isListening)
        XCTAssertFalse(voiceRecognizer.isSpeechDetected)
        XCTAssertEqual(voiceRecognizer.audioLevel, 0.0)
        XCTAssertNil(voiceRecognizer.errorMessage)
        XCTAssertEqual(voiceRecognizer.recognizedText, "")
    }
    
    func testStartRecordingWithoutAuthorization() {
        voiceRecognizer.isAuthorized = false
        voiceRecognizer.startRecording()
        
        XCTAssertFalse(voiceRecognizer.isRecording)
        XCTAssertEqual(voiceRecognizer.errorMessage, "Please grant microphone and speech recognition permissions")
    }
    
    func testStartRecordingWithAuthorization() {
        voiceRecognizer.isAuthorized = true
        voiceRecognizer.startRecording()
        
        XCTAssertTrue(voiceRecognizer.isRecording)
        XCTAssertTrue(mockAudioEngine.isRunning)
        XCTAssertNotNil((mockAudioEngine.inputNode as? MockAudioInputNode)?.tapBlock)
    }
    
    func testStopRecording() {
        voiceRecognizer.isAuthorized = true
        voiceRecognizer.startRecording()
        voiceRecognizer.stopRecording()
        
        XCTAssertFalse(voiceRecognizer.isRecording)
        XCTAssertFalse(mockAudioEngine.isRunning)
        XCTAssertNil((mockAudioEngine.inputNode as? MockAudioInputNode)?.tapBlock)
    }
    
    func testHandleNoSpeechDetectedError() {
        voiceRecognizer.isAuthorized = true
        voiceRecognizer.startRecording()
        
        let error = NSError(domain: "com.apple.SpeechRecognition", code: 0, userInfo: [NSLocalizedDescriptionKey: "No speech detected"])
        voiceRecognizer.handleSpeechRecognitionError(error)
        
        XCTAssertEqual(voiceRecognizer.noSpeechRetryCount, 1)
        XCTAssertTrue(voiceRecognizer.isRecording)
    }
    
    func testHandleSpeechRecognitionServiceError() {
        voiceRecognizer.isAuthorized = true
        voiceRecognizer.startRecording()
        
        let error = NSError(domain: "kAFAssistantErrorDomain", code: 1101, userInfo: nil)
        voiceRecognizer.handleSpeechRecognitionError(error)
        
        XCTAssertEqual(voiceRecognizer.retryCount, 1)
        XCTAssertTrue(voiceRecognizer.isRecording)
    }
    
    func testAudioLevelDetection() {
        voiceRecognizer.isAuthorized = true
        voiceRecognizer.startRecording()
        
        // Create a mock audio buffer
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        
        // Fill buffer with some audio data
        let channelData = buffer.floatChannelData?[0]
        for i in 0..<Int(buffer.frameCapacity) {
            channelData?[i] = 0.5 // Simulate some audio input
        }
        buffer.frameLength = buffer.frameCapacity
        
        // Simulate audio input
        (mockAudioEngine.inputNode as? MockAudioInputNode)?.tapBlock?(buffer, AVAudioTime())
        
        XCTAssertGreaterThan(voiceRecognizer.audioLevel, 0)
        XCTAssertTrue(voiceRecognizer.isSpeechDetected)
    }
    
    func testInstallTap() {
        voiceRecognizer.start()
        XCTAssertNotNil(mockAudioEngine.inputNode as? MockAudioInputNode)
    }
    
    func testRemoveTap() {
        voiceRecognizer.start()
        voiceRecognizer.stop()
        XCTAssertNil((mockAudioEngine.inputNode as? MockAudioInputNode)?.tapBlock)
    }
    
    func testSilenceTimeout() {
        let maxRetries = 3
        voiceRecognizer.start()
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let silenceBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        
        // Fill buffer with silence (zeros)
        for i in 0..<Int(silenceBuffer.frameLength) {
            silenceBuffer.floatChannelData?[0][i] = 0.0
        }
        
        // Simulate silence for maxRetries + 1 times
        for _ in 0...maxRetries {
            _ = voiceRecognizer.checkAudioLevel(silenceBuffer)
        }
        
        XCTAssertEqual(voiceRecognizer.checkAudioLevel(silenceBuffer), 0.0)
        XCTAssertFalse(voiceRecognizer.isSpeechDetected)
    }
    
    func testUIStateTransitions() {
        // Start recording
        voiceRecognizer.startRecording()
        XCTAssertTrue(voiceRecognizer.isRecording)
        XCTAssertTrue(voiceRecognizer.isListening)
        XCTAssertFalse(voiceRecognizer.isSpeechDetected)
        XCTAssertEqual(voiceRecognizer.audioLevel, 0.0)
        
        // Simulate speech detection
        let buffer = createMockBuffer(level: 0.0003) // Above threshold
        voiceRecognizer.checkAudioLevel(buffer)
        XCTAssertTrue(voiceRecognizer.isSpeechDetected)
        XCTAssertTrue(voiceRecognizer.isListening)
        
        // Simulate silence
        let silenceBuffer = createMockBuffer(level: 0.0001) // Below threshold
        voiceRecognizer.checkAudioLevel(silenceBuffer)
        XCTAssertFalse(voiceRecognizer.isSpeechDetected)
        XCTAssertTrue(voiceRecognizer.isListening)
        
        // Simulate final result
        let mockResult = MockSpeechRecognitionResult(transcription: MockTranscription(formattedString: "Test"), isFinal: true)
        mockSpeechRecognizer.simulateResult(mockResult)
        XCTAssertFalse(voiceRecognizer.isRecording)
        XCTAssertFalse(voiceRecognizer.isListening)
        XCTAssertFalse(voiceRecognizer.isSpeechDetected)
        XCTAssertEqual(voiceRecognizer.audioLevel, 0.0)
    }
    
    func testErrorHandling() {
        voiceRecognizer.startRecording()
        
        // Simulate error
        let error = NSError(domain: "kAFAssistantErrorDomain", code: 1101, userInfo: nil)
        mockSpeechRecognizer.simulateError(error)
        
        XCTAssertFalse(voiceRecognizer.isRecording)
        XCTAssertFalse(voiceRecognizer.isListening)
        XCTAssertFalse(voiceRecognizer.isSpeechDetected)
        XCTAssertEqual(voiceRecognizer.audioLevel, 0.0)
        XCTAssertNotNil(voiceRecognizer.errorMessage)
    }
    
    private func createMockBuffer(level: Float) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        buffer.frameLength = 1024
        
        let channelData = buffer.floatChannelData?[0]
        for i in 0..<Int(buffer.frameLength) {
            channelData?[i] = level
        }
        
        return buffer
    }
} 