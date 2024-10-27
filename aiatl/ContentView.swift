import SwiftUI
import Speech
import UIKit
import AVFoundation
import AVKit
import GoogleGenerativeAI

// MARK: - Main Content View
struct ContentView: View {
    @ObservedObject var speechRecognizer = SpeechRecognizer()

    @State private var selectedImage: UIImage? = nil
    @State private var nutritionFacts: String = "Nutrition facts will appear here."
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showImagePickerForVideo = false
    @State private var showImagePickerForGemini = false
    @State private var videoURL: URL? = nil
    @State private var isHumanDetectionActive = false
    @State private var capturedImage: UIImage? = nil

    @State private var userPrompt: String = ""
    @State private var generatedText: String = "Generated content will appear here."
    
    private let generativeModel: GenerativeModel
    
    init() {
        self.generativeModel = GenerativeModel(name: "gemini-1.5-flash", apiKey: APIKey.default)
    }
    // Define the speech synthesizer
    private let speechSynthesizer = AVSpeechSynthesizer()
    let toolAgent = ToolAgent(tools: [NutritionFactsTool()]) // Ensure NutritionFactsTool conforms to ToolProtocol

    
    var body: some View {
        VStack {
            Text("Enter your prompt below:")
                .font(.headline)
            TextField("Type your prompt here...", text: $userPrompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Text(generatedText)
                .padding()
                .multilineTextAlignment(.center)
            
            Button("Generate Content with Gemini") {
                Task {
                    await generateContent()
                }
            }
            .padding()
            Text(generatedText)
                .padding()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text(speechRecognizer.recognizedText)
                .font(.title)
                .padding()
            
            Button("Select Image for Nutrition Facts") {
                showImagePickerForGemini = true
            }
            .padding()
            
            Button("Get Nutrition Facts") {
                if let image = selectedImage {
                    getNutritionFactsFromGemini(image: image)
                } else {
                    nutritionFacts = "Please select an image first."
                    speak(text: nutritionFacts) // Speak error if no image selected
                }
            }
            .padding()
            
            Button("Speak Nutrition Facts") {
                speakNutritionFacts()
            }
            .padding()
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
            
            Text(nutritionFacts)
                .padding()
                .onChange(of: nutritionFacts) { newValue in
                    speak(text: newValue) // Automatically speak new nutrition facts
                }
        }
        .sheet(isPresented: $showImagePickerForGemini) {
            ImagePickerForGemini(selectedImage: $selectedImage)
        }
    }
    // Function to call the Gemini API and update generatedText
    func generateContent() async {
        guard !userPrompt.isEmpty else {
            self.generatedText = "Please enter a prompt to generate content."
            return
        }
        
        do {
            let response = try await generativeModel.generateContent(userPrompt)
            if let text = response.text {
                DispatchQueue.main.async {
                    self.generatedText = text
                }
            } else {
                self.generatedText = "No content generated."
            }
        } catch {
            self.generatedText = "Error: \(error.localizedDescription)"
        }
    }
    func getNutritionFactsFromGemini(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG data")
            return
        }
        
        let generativeModel = GenerativeModel(
            name: "gemini-1.5-flash",
            apiKey: APIKey.default
        )
        
        let prompt = "Can you tell me the nutrition facts for the item in this photo?"
        
        Task {
            do {
                let response = try await generativeModel.generateContent(image, prompt)
                if let text = response.text {
                    DispatchQueue.main.async {
                        self.nutritionFacts = text
                        self.speakNutritionFacts() // Speak immediately after setting the text
                        print("Received nutrition facts: \(text)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.nutritionFacts = "Failed to retrieve nutrition facts: \(error.localizedDescription)"
                    print("Error fetching nutrition facts: \(error.localizedDescription)")
                }
            }
        }
    }

    
    // MARK: - Text-to-Speech Function
    private func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynthesizer.speak(utterance)
    }
    func speakNutritionFacts() {
        let utterance = AVSpeechUtterance(string: nutritionFacts)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
}





// MARK: - Video Player View
struct VideoPlayerView: View {
    var videoURL: URL
    
    var body: some View {
        VideoPlayer(player: AVPlayer(url: videoURL))
            .frame(height: 300)
            .cornerRadius(10)
            .padding()
    }
}
