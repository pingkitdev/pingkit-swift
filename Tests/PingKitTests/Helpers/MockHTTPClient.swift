import Foundation
@testable import PingKit

final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    var statusCode: Int = 201
    var responseData: Data = Data()
    var error: Error?
    private(set) var lastRequest: URLRequest?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        if let error { throw error }
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (responseData, response)
    }

    // Convenience: set a JSON response body
    func setJSONResponse(_ dict: [String: Any]) {
        responseData = try! JSONSerialization.data(withJSONObject: dict)
    }

    // Convenience: set an error response
    func setErrorResponse(code: String, message: String) {
        setJSONResponse(["error": ["code": code, "message": message]])
    }

    // Convenience: set a success response
    func setSuccessResponse(id: String = "fb_test123", status: String = "new") {
        setJSONResponse(["id": id, "status": status])
    }
}
