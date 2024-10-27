import Foundation
import Speech

class SpeechRecognizer: ObservableObject {
    @Published var recognizedText = "Tap to start speaking"
    @Published var isListening = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    self.recognizedText = "Speech recognition access denied by user."
                case .restricted:
                    self.recognizedText = "Speech recognition restricted on this device."
                case .notDetermined:
                    self.recognizedText = "Speech recognition not yet authorized."
                @unknown default:
                    fatalError()
                }
            }
        }
    }
    
    func startListening() {
        guard !isListening else { return }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            self.recognizedText = "Speech recognition not available."
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                DispatchQueue.main.async {
                    self.stopListening()
                }
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.recognizedText = "Listening..."
                self.isListening = true
            }
        } catch {
            DispatchQueue.main.async {
                self.recognizedText = "Audio engine failed to start: \(error.localizedDescription)"
                self.isListening = false
            }
        }
    }
    
    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionTask?.cancel()
            recognitionRequest = nil
            recognitionTask = nil
        }
        
        DispatchQueue.main.async {
            self.recognizedText = "Tap to start speaking"
            self.isListening = false
        }
    }
}
