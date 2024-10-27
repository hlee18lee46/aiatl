import Foundation

// Ensure this file includes ToolProtocol.swift in the target setup

struct NutritionFactsTool: ToolProtocol {
    var name: String { return "NutritionFactsTool" }
    
    func canHandle(input: String) -> Bool {
        return input.contains("nutrition")
    }

    func execute(input: String, context: [String: Any]) async throws -> String {
        // Implementation for retrieving nutrition facts
        return "Nutrition facts for \(input)"
    }
}
