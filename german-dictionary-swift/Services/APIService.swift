import Foundation

/// Das Antwort-Schema der Gemini API für das JSON-Parsing
struct GeminiResponse: Decodable {
    let word: String
    let meaning: String
}

final class APIService {
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case parsingError
        case noData
        case missingAPIKey
        
        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "API-Key konnte nicht aus der Secret.plist geladen werden. Bitte überprüfe die Datei."
            default:
                return "Es gab einen Fehler bei der KI-Verarbeitung."
            }
        }
    }
    
    /// Liest den API-Key dynamisch und sicher aus der Secret.plist aus
    private var apiKey: String? {
        // Sucht den Pfad zur Secret.plist im App-Bundle
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) else {
            print("❌ Fehler: Secrets.plist wurde im Projekt nicht gefunden!")
            return nil
        }
        
        // Holt den Wert für den Key ab
        return dict["GEMINI_API_KEY"] as? String
    }
    
    /// Sendet den Text an die Gemini-API und extrahiert das korrigierte Kernwort sowie die Bedeutung
    func searchWordViaAI(userInput: String) async throws -> GeminiResponse {
        // 1. Sicherstellen, dass der Key erfolgreich aus der Plist gelesen wurde
        guard let currentKey = apiKey, !currentKey.isEmpty, currentKey != "YOUR_API_KEY" else {
            throw APIError.missingAPIKey
        }
        
        // 2. URL mit API-Key als Query-Parameter aufbauen
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw APIError.invalidURL
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: currentKey)]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        // 3. Prompt definieren
        let prompt = """
        너는 독일어 전문가이자 유능한 번역가야. 입력된 독일어 데이터의 오타를 교정하고 정확한 한국어 뜻을 추출해줘.
        
        [처리 규칙]
        1. 오타 교정: 유저가 입력한 독일어(단어, 숙어, 관용구, 슬랭 등)에 오타나 대소문자 오류가 있다면 올바르게 교정해줘.
        2. 뜻풀이 (meaning):
           - 단어뿐만 아니라 숙어(Redewendung)나 슬랭(Umgangssprache)인 경우에도 핵심 한국어 의미를 정확히 짚어줘.
           - 🚨 [중요 - 글자 수 제한]: 한국어 설명은 반드시 공백을 포함하여 **최대 60자 이내**로 명확하고 간결하게 요약해줘. 화면에 예쁘게 나오도록 불필요하게 길게 늘어놓지 마.
        
        유저 입력값: { \(userInput) }
        """
        
        // 4. Request-Body für Structured Outputs aufbauen
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": [
                    "type": "OBJECT",
                    "properties": [
                        "word": ["type": "STRING", "description": "Das korrigierte deutsche Wort."],
                        "meaning": ["type": "STRING", "description": "Die koreanische Bedeutung."]
                    ],
                    "required": ["word", "meaning"]
                ],
                "temperature": 0.2
            ]
        ]
        
        // 5. URLRequest konfigurieren
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 6. API asynchron aufrufen
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        // 7. JSON-String aus der Gemini-Verschachtelung extrahieren
        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = jsonObject["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let jsonStringText = firstPart["text"] as? String,
              let rawJsonData = jsonStringText.data(using: .utf8) else {
            throw APIError.parsingError
        }
        
        // 8. Den extrahierten JSON-String in unser GeminiResponse-Struct parsen
        let decodedResult = try JSONDecoder().decode(GeminiResponse.self, from: rawJsonData)
        return decodedResult
    }
}
