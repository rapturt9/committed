import Foundation

actor FatebookService {
    private let apiKey: String
    private let baseURL = "https://fatebook.io/api/v0"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    struct GetQuestionResponse: Decodable {
        let title: String?
        let resolveBy: String?
        let resolution: String?
        let forecasts: [ForecastData]?

        struct ForecastData: Decodable {
            let forecast: Double?
        }
    }

    func createQuestion(title: String, resolveBy: Date, forecast: Double, tags: [String] = ["committed"]) async throws -> String? {
        guard !apiKey.isEmpty else {
            NSLog("[Fatebook] No API key")
            return nil
        }

        let dateFormatter = ISO8601DateFormatter()
        let resolveByStr = dateFormatter.string(from: resolveBy)

        var queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "resolveBy", value: resolveByStr),
            URLQueryItem(name: "forecast", value: String(forecast))
        ]

        // Tags are repeated params: &tags=tag1&tags=tag2
        for tag in tags {
            queryItems.append(URLQueryItem(name: "tags", value: tag))
        }

        var components = URLComponents(string: "\(baseURL)/createQuestion")!
        components.queryItems = queryItems

        guard let url = components.url else { return nil }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? ""
            NSLog("[Fatebook] createQuestion failed: status \(statusCode), body: \(body)")
            return nil
        }

        let responseStr = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        NSLog("[Fatebook] Created: \(responseStr ?? "nil")")
        return responseStr
    }

    func getQuestion(questionId: String) async throws -> GetQuestionResponse? {
        guard !apiKey.isEmpty else { return nil }

        var components = URLComponents(string: "\(baseURL)/getQuestion")!
        components.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "questionId", value: questionId)
        ]

        guard let url = components.url else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(GetQuestionResponse.self, from: data)
    }
}
