import Foundation

protocol ToolProtocol {
    var name: String { get }
    func canHandle(input: String) -> Bool
    func execute(input: String, context: [String: Any]) async throws -> String
}
