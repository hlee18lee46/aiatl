// AttachPhotoTool.swift
import Foundation
import UIKit

struct AttachPhotoTool: ToolProtocol {
    var name: String { return "AttachPhotoTool" }
    var description: String { return "Prompts the user to attach a photo by opening the camera." }
    
    func canHandle(input: String) -> Bool {
        // Define keywords to trigger attaching a photo
        let keywords = ["attach photo", "photo", "picture", "attach picture"]
        return keywords.contains { input.localizedCaseInsensitiveContains($0) }
    }

    func execute(input: String, context: [String: Any]) async throws -> String {
        // Instead of opening the camera, return a signal message to ContentView
        return "Please open the camera to take a photo."
    }
}
