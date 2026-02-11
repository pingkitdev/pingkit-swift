import Foundation

enum APIClient {
    static func submitFeedback(
        text: String,
        imageData: Data?,
        metadata: DeviceMetadata,
        customMetadata: [String: String]?,
        endpoint: String,
        apiKey: String,
        attestAssertion: String?,
        attestKeyId: String?
    ) async throws -> FeedbackResult {
        let url = URL(string: "\(endpoint)/v1/feedback")!

        var jsonBody: [String: Any] = [
            "text": text,
            "device_model": metadata.deviceModel,
            "os_version": metadata.osVersion,
            "app_version": metadata.appVersion,
            "app_build": metadata.appBuild,
            "locale": metadata.locale,
            "timezone": metadata.timezone,
        ]

        if let customMetadata, !customMetadata.isEmpty {
            jsonBody["custom_metadata"] = customMetadata
        }

        var request: URLRequest
        var bodyData: Data

        if let imageData {
            // Multipart form data
            let boundary = UUID().uuidString
            request = URLRequest(url: url)
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()

            // JSON part
            let jsonData = try JSONSerialization.data(withJSONObject: jsonBody)
            body.appendMultipartField(name: "json", data: jsonData, contentType: "application/json", boundary: boundary)

            // Image part
            body.appendMultipartField(name: "image", data: imageData, contentType: "image/jpeg", filename: "screenshot.jpg", boundary: boundary)

            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            bodyData = body
        } else {
            // JSON only
            request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            bodyData = try JSONSerialization.data(withJSONObject: jsonBody)
        }

        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = 30

        // App Attest headers
        if let attestAssertion, let attestKeyId {
            request.setValue(attestAssertion, forHTTPHeaderField: "X-Apple-Attest-Assertion")
            request.setValue(attestKeyId, forHTTPHeaderField: "X-Apple-Attest-Key-Id")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PingKitError.networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 201:
            let result = try JSONDecoder().decode(SubmitResponse.self, from: data)
            return FeedbackResult(id: result.id, status: result.status)
        case 401:
            throw PingKitError.unauthorized
        case 403:
            throw PingKitError.attestRequired
        case 413:
            throw PingKitError.imageTooLarge
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
            let errorBody = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            if errorBody?.error.code == "PLAN_LIMIT" {
                throw PingKitError.planLimitReached
            }
            throw PingKitError.rateLimited(retryAfter: retryAfter)
        default:
            let errorBody = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw PingKitError.serverError(
                code: errorBody?.error.code ?? "UNKNOWN",
                message: errorBody?.error.message ?? "An unexpected error occurred"
            )
        }
    }
}

// MARK: - Response types

private struct SubmitResponse: Decodable {
    let id: String
    let status: String
}

private struct ErrorResponse: Decodable {
    let error: ErrorDetail

    struct ErrorDetail: Decodable {
        let code: String
        let message: String
    }
}

// MARK: - Multipart helpers

private extension Data {
    mutating func appendMultipartField(
        name: String,
        data: Data,
        contentType: String,
        filename: String? = nil,
        boundary: String
    ) {
        var header = "--\(boundary)\r\n"
        if let filename {
            header += "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n"
        } else {
            header += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        }
        header += "Content-Type: \(contentType)\r\n\r\n"

        append(header.data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}
