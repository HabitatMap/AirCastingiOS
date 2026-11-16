// Created by Lunar on 30/04/2026.
//
// Phase 4: V2 fixed-session backend endpoint.
//
// POSTs to `/api/v3/fixed_sessions` with the JSON described in
// `ble_mobile_app_guide_ios.md` §7 and returns the typed Decodable response.
// The `session_token` (32-hex chars) and `streams[].sensor_type_id` values
// are then fed into `V2BinaryProtocol.buildNewSessionConfigFixed`.

import Foundation
import Resolver

enum V2FixedSessionAPIError: Error {
    case missingDeviceModel
    case missingStreamSensorType
}

enum V2FixedSessionAPI {
    struct AirbeamParams: Encodable {
        let mac_address: String
        let model: String
        let name: String
    }

    struct StreamRequestParams: Encodable {
        let sensor_name: String
        let unit_symbol: String
    }

    struct RequestBody: Encodable {
        // `uuid` is a plain String (not `SessionUUID`) on purpose. Swift's
        // auto-synthesised Codable for `struct SessionUUID { let rawValue: String }`
        // emits a nested `{"rawValue": "..."}` object — the V3 BE strict-decodes
        // the field and ends up with a session keyed by a different/null uuid,
        // so when the device later POSTs measurements to the uuid the app sent
        // it via BLE, the BE returns a non-2xx and the firmware Nacks 0x02.
        let uuid: String
        let title: String
        // Sent for every fixed session, indoor included — indoor / locationless
        // sessions carry the `(200, 200)` sentinel location so the numerals go
        // up unchanged (BE derives the session TZ from the `time_zone` field
        // below, not from these coords). Optional only so a session with no
        // stored location at all encodes `null` rather than a bogus 0. Mirrors
        // Android `CreateFixedSessionV3Body` (`latitude = session.location?.latitude`).
        let latitude: Double?
        let longitude: Double?
        let contribute: Bool
        let is_indoor: Bool
        // Phone's TZ id (e.g. "Europe/Warsaw"). BE stores it as the session's
        // `time_zone` and returns all timestamp numerals in this wall clock, so
        // the app no longer has to UTC-shift indoor / locationless fixed
        // sessions on download. Mirrors Android `time_zone` on the V3 body.
        let time_zone: String
        let airbeam: AirbeamParams
        let streams: [StreamRequestParams]
    }

    struct StreamResponse: Decodable, Hashable {
        let sensor_name: String
        let sensor_type_id: Int
    }

    struct Response: Decodable {
        let location: String?
        let session_token: String
        let streams: [StreamResponse]
    }
}

final class V2FixedSessionAPIService {
    @Injected private var urlProvider: URLProvider
    @Injected private var apiClient: APIClient
    @Injected private var responseValidator: HTTPResponseValidator
    @Injected private var authorisationService: RequestAuthorisationService

    private lazy var encoder: JSONEncoder = JSONEncoder()
    private lazy var decoder: JSONDecoder = JSONDecoder()

    @discardableResult
    func createFixedSession(body: V2FixedSessionAPI.RequestBody,
                            completion: @escaping (Result<V2FixedSessionAPI.Response, Error>) -> Void) -> Cancellable {
        // The V3 endpoint is HTTPS-only on the production load balancer.
        // Posting over plain HTTP triggers a 301 → HTTPS that URLSession
        // follows as a GET, and the response body is the redirect HTML
        // ("Unexpected character '<' around line 1, column 1.") instead of
        // the typed JSON. Force HTTPS / port 443 regardless of the base URL.
        // Mirrors Android commits `caf2dc3b0` / `39c0a59b0`.
        let url = httpsURLForV3Endpoint("api/v3/fixed_sessions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let bodyData = try encoder.encode(body)
            request.httpBody = bodyData
            if let preview = String(data: bodyData, encoding: .utf8) {
                Log.info("V2 fixed session POST body: \(preview)")
            }
            try authorisationService.authorise(request: &request)
        } catch {
            completion(.failure(error))
            return EmptyCancellable()
        }
        return apiClient.requestTask(for: request) { [responseValidator, decoder] result, _ in
            completion(result.tryMap({
                try responseValidator.validate(response: $0.response, data: $0.data)
                return try decoder.decode(V2FixedSessionAPI.Response.self, from: $0.data)
            }))
        }
    }

    private func httpsURLForV3Endpoint(_ path: String) -> URL {
        let base = urlProvider.baseAppURL
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false) ?? URLComponents()
        components.scheme = "https"
        if components.port == 80 { components.port = nil }
        let resolved = components.url ?? base
        return resolved.appendingPathComponent(path)
    }
}
