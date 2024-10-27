import Foundation
import UIKit
import AVFoundation
import GoogleGenerativeAI

struct SugarContentTool: ToolProtocol {
    var name: String { return "SugarContentTool" }
    var description: String { return "Provides sugar intake of a given image of food." } // Implementing description
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    func canHandle(input: String) -> Bool {
        // Define keywords related to nutrition facts
        let keywords = ["sugar", "carbohydrates", "sugar intake", "sugar content"]
        
        // Check if any of the keywords are present in the input string
        return keywords.contains { input.localizedCaseInsensitiveContains($0) }
    }
    
    func execute(input: String, context: [String: Any]) async throws -> String {
        guard let image = context["image"] as? UIImage else {
            return "No image provided for sugar intake."
        }
        
        let nutritionFacts = try await getNutritionFactsFromGemini(image: image)
        speak(text: nutritionFacts)
        return nutritionFacts
    }
    
    private func getNutritionFactsFromGemini(image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "SugarContentTool", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])
        }
        
        let generativeModel = GenerativeModel(
            name: "gemini-1.5-flash",
            apiKey: APIKey.default
        )
        
        let prompt = "Can you tell me the sugars in grams of the item in this photo?"
        
        let response = try await generativeModel.generateContent(image, prompt)
        if let text = response.text {
            return text
        } else {
            throw NSError(domain: "SugarContentTool", code: 2, userInfo: [NSLocalizedDescriptionKey: "No sugar intake found in the response."])
        }
    }
    
    private func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynthesizer.speak(utterance)
    }
}
