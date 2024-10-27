import Foundation
import LangGraph // Assuming LangGraph is needed for ToolProtocol and AgentProtocol
import LangChain


struct ToolAgent {
    let tools: [ToolProtocol]

    init(tools: [ToolProtocol]) {
        self.tools = tools
    }

    func respond(to input: String, context: [String: Any] = [:]) async throws -> String {
        for tool in tools {
            if tool.canHandle(input: input) {
                // Pass context when calling `execute`
                return try await tool.execute(input: input, context: context)
            }
        }
        return "No suitable tool found for the input."
    }
}
