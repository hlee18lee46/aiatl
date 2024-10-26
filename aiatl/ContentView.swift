import SwiftUI
import Speech
import UIKit
import AVFoundation
import AVKit
import GoogleGenerativeAI

// MARK: - Speech Recognition Class
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

// MARK: - Image Picker for Video Capture
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Image Picker for Gemini Nutrition Analysis
struct ImagePickerForGemini: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePickerForGemini
        
        init(_ parent: ImagePickerForGemini) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }
    }
}
enum APIKey {
    // Fetch the API key from Info.plist
    static var `default`: String {
        guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist") else {
            fatalError("Couldn't find Info.plist.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "GEMINI_API_KEY") as? String else {
            fatalError("Couldn't find key 'GEMINI_API_KEY' in 'Info.plist'.")
        }
        return value
    }
}
// MARK: - Main Content View
struct ContentView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var nutritionFacts: String = "Nutrition facts will appear here."
    @State private var showImagePicker = false

    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            }
            
            Text(nutritionFacts)
                .padding()
            
            Button("Select Image for Nutrition Facts") {
                showImagePicker = true
            }
            
            Button("Get Nutrition Facts") {
                if let image = selectedImage {
                    getNutritionFactsFromGemini(image: image)
                } else {
                    nutritionFacts = "Please select an image first."
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
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

        let prompt = "what's in the photo?, If it shows food/drinks then show nutrition facts"

        Task {
            do {
                let response = try await generativeModel.generateContent(image, prompt)
                if let text = response.text {
                    DispatchQueue.main.async {
                        self.nutritionFacts = text
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.nutritionFacts = "Failed to retrieve nutrition facts: \(error.localizedDescription)"
                }
            }
        }
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
