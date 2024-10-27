import Foundation

protocol ToolProtocol {
    var name: String { get }
    var description: String { get } // New property for description
    func canHandle(input: String) -> Bool
    func execute(input: String, context: [String: Any]) async throws -> String
}
