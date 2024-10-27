import SwiftUI
import Speech
import UIKit
import AVFoundation
import AVKit
import GoogleGenerativeAI
import LangChain
import LangGraph

struct ContentView: View {
    @ObservedObject var speechRecognizer = SpeechRecognizer()
    @State private var userQuery: String = ""
    @State private var agentResponse: String = "Response will appear here."
    
    @State private var selectedImage: UIImage? = nil
    @State private var showCamera = false
    @State private var userPrompt: String = ""
    @State private var toolResponse: String = ""
    
    @State private var nutritionFacts: String = "Nutrition facts will appear here."
    @State private var showImagePickerForGemini = false
    
    let toolAgent = ToolAgent(tools: [AttachPhotoTool(), NutritionFactsTool(), GeminiLLMTool(), SugarContentTool(), BusNumberTool()])
    // Speech synthesizer for reading responses to the user
    private let speechSynthesizer = AVSpeechSynthesizer()
    init() {
        configureAudioSession()  // Configure audio session on init
    }
    var body: some View {
        VStack {
            // Display the tool response
            Text(toolResponse)
                .padding()
                .multilineTextAlignment(.center)
            Text(speechRecognizer.recognizedText)
                .font(.title)
                .padding()
            
            // Big "Speak" button to start voice recognition and agent execution
            Button(action: {
                // Start voice recognition
                if speechRecognizer.isListening {
                    speechRecognizer.stopListening()
                } else {
                    speechRecognizer.startListening()
                }
                
                // Once recognized text is updated, process it
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    Task {
                        await handleVoiceCommand()
                    }
                }
            }) {
                Text(speechRecognizer.isListening ? "Stop Listening" : "Speak")
                    .font(.title)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            // Display the selected image (if any)
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
            }
        }
        .sheet(isPresented: $showImagePickerForGemini) {
            ImagePickerForGemini(selectedImage: $selectedImage)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(capturedImage: $selectedImage)
        }

    }
    
    // Process the recognized voice command
    func handleVoiceCommand() async {
        guard !speechRecognizer.recognizedText.isEmpty else {
            speak(text: "Please say something to use the tool.")
            return
        }

        // Prepare context with selected image if available
        var context: [String: Any] = [:]
        if let image = selectedImage {
            context["image"] = image
        }

        do {
            // Send the recognized text to the tool agent
            let response = try await toolAgent.respond(to: speechRecognizer.recognizedText, context: context)
            DispatchQueue.main.async {
                self.toolResponse = response
                self.speak(text: response) // Speak the tool's response

                // Check if response requires opening camera or image picker
                // Open camera or image picker based on tool response
                if response.contains("Please open the camera") {
                    self.showCamera = true
                } else if response.contains("Please attach a photo") {
                    self.showImagePickerForGemini = true
                }
            }
        } catch {
            let errorMessage = "Error: \(error.localizedDescription)"
            self.toolResponse = errorMessage
            self.speak(text: errorMessage)
        }
    }
    
    // Text-to-speech function to speak any text
    private func speak(text: String) {
        // Stop any ongoing speech before starting a new one
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0 // Ensures maximum volume
        speechSynthesizer.speak(utterance)

    }
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.duckOthers, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category and mode: \(error.localizedDescription)")
        }
    }
    
}
