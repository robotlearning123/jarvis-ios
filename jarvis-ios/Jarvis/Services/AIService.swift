import Foundation

class AIService {
    static let shared = AIService()

    // Replace with your actual API endpoint
    private let apiURL = "https://jarvis-api.fly.dev/api/chat"

    func sendMessage(_ text: String) async throws -> String {
        guard let url = URL(string: apiURL) else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "message": text,
            "context": "voice-conversation"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.serverError
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let reply = json["reply"] as? String {
            return reply
        }

        throw AIError.invalidResponse
    }

    // Fallback: Local responses when offline
    func getLocalResponse(for input: String) -> String {
        let lowercased = input.lowercased()

        if lowercased.contains("hello") || lowercased.contains("hi") {
            return "Hello! I'm JARVIS, your personal AI assistant. How may I help you today?"
        } else if lowercased.contains("how are you") {
            return "I'm functioning optimally. All systems operational. How can I assist you?"
        } else if lowercased.contains("weather") {
            return "I don't have access to real-time weather data yet, but I can help you with other tasks."
        } else if lowercased.contains("time") {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "The current time is \(formatter.string(from: Date()))."
        } else if lowercased.contains("date") {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return "Today is \(formatter.string(from: Date()))."
        } else {
            return "I understand you said: '\(input)'. I'm currently in demo mode. How else can I assist you?"
        }
    }
}

enum AIError: Error {
    case invalidURL
    case serverError
    case invalidResponse
}
