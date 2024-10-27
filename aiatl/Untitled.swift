//
//  Untitled.swift
//  aiatl
//
//  Created by Han Lee on 10/26/24.
//
/*
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
    
    // Initialize ToolAgent with GeminiLLMTool and NutritionFactsTool
    private let toolAgent = ToolAgent(tools: [GeminiLLMTool(), NutritionFactsTool()])

    var body: some View {
        VStack(spacing: 20) {
            Text("AI Query with Tools")
                .font(.title)
                .padding()

            // TextField for user input
            TextField("Enter your query", text: $userQuery)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            // Button to trigger agent response
            Button(action: {
                Task {
                    await handleQuery()
                }
            }) {
                Text("Get Response")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }

            // Display agent response
            Text(agentResponse)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
        .padding()
    }
    
    // Handle user query and get agent response
    private func handleQuery() async {
        do {
            // Send query to agent
            let response = try await toolAgent.respond(to: userQuery, context: [:])
            DispatchQueue.main.async {
                self.agentResponse = response
            }
        } catch {
            self.agentResponse = "Failed to get a response: \(error.localizedDescription)"
        }
    }
}
*/
