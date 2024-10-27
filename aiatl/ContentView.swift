import SwiftUI
import Speech
import UIKit
import AVFoundation
import AVKit
import GoogleGenerativeAI
import LangChain
import LangGraph

struct ContentView: View {
    @State private var userQuery: String = ""
    @State private var agentResponse: String = "Response will appear here."
    
    @State private var selectedImage: UIImage? = nil
    @State private var showCamera = false
    @State private var userPrompt: String = ""
    @State private var toolResponse: String = ""
    
    let toolAgent = ToolAgent(tools: [AttachPhotoTool(), NutritionFactsTool(), GeminiLLMTool()])

    var body: some View {
        VStack {
            TextField("Type your prompt here...", text: $userPrompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Use Tool") {
                Task {
                    await handleToolRequest()
                }
            }
            .padding()
            
            Text(toolResponse)
                .padding()
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView(capturedImage: $selectedImage)
        }
    }
    
    func handleToolRequest() async {
        do {
            // Build the context with the selected image if it exists
            var context: [String: Any] = [:]
            if let image = selectedImage {
                context["image"] = image
            }

            // Send the user prompt to the agent
            let response = try await toolAgent.respond(to: userPrompt, context: context)
            
            DispatchQueue.main.async {
                self.toolResponse = response
                
                // Check if the response requires opening the camera
                if response.contains("Please open the camera") {
                    self.showCamera = true
                }
            }
        } catch {
            self.toolResponse = "Error: \(error.localizedDescription)"
        }
    }
}
