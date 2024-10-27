import Foundation
import UIKit
import AVFoundation
import GoogleGenerativeAI

struct NutritionFactsTool: ToolProtocol {
    var name: String { return "NutritionFactsTool" }
    var description: String { return "Provides nutrition facts for a given image of food." } // Implementing description
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    func canHandle(input: String) -> Bool {
        // Define keywords related to nutrition facts
        let keywords = ["nutrition", "calories", "ingredients", "nutritional information"]
        
        // Check if any of the keywords are present in the input string
        return keywords.contains { input.localizedCaseInsensitiveContains($0) }
    }
    
    func execute(input: String, context: [String: Any]) async throws -> String {
        guard let image = context["image"] as? UIImage else {
            return "No image provided for nutrition facts."
        }
        
        let nutritionFacts = try await getNutritionFactsFromGemini(image: image)
        speak(text: nutritionFacts)
        return nutritionFacts
    }
    
    private func getNutritionFactsFromGemini(image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "NutritionFactsTool", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])
        }
        
        let generativeModel = GenerativeModel(
            name: "gemini-1.5-flash",
            apiKey: APIKey.default
        )
        
        let prompt = "Can you tell me the nutrition facts for the item in this photo?"
        
        let response = try await generativeModel.generateContent(image, prompt)
        if let text = response.text {
            return text
        } else {
            throw NSError(domain: "NutritionFactsTool", code: 2, userInfo: [NSLocalizedDescriptionKey: "No nutrition facts found in the response."])
        }
    }
    
    private func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynthesizer.speak(utterance)
    }
}
