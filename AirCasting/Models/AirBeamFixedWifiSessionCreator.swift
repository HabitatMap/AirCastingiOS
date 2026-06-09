// Created by Lunar on 11/05/2021.
//

import Foundation
import CoreLocation
import Resolver

final class AirBeamFixedWifiSessionCreator: SessionCreator {
    enum AirBeamSessionCreatorError: Swift.Error {
        case invalidCreateSessionContext(CreateSessionContext)
        case missingSensorTypeID
    }
    @Injected private var userAuthenticationSession: UserAuthenticationSession
    @Injected private var persistence: SessionCreatingStorage
    @Injected private var uiStore: UIStorage
    @Injected private var bluetoothConnectionHandler: BluetoothConnectionHandler
    private let createSessionService: CreateSessionAPIService
    private let v2FixedSessionService: V2FixedSessionAPIService

    convenience init() {
        self.init(createSessionService: CreateSessionAPIService(),
                  v2FixedSessionService: V2FixedSessionAPIService())
    }

    init(createSessionService: CreateSessionAPIService,
         v2FixedSessionService: V2FixedSessionAPIService) {
        self.createSessionService = createSessionService
        self.v2FixedSessionService = v2FixedSessionService
    }

    func createSession(_ sessionContext: CreateSessionContext, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sessionType = sessionContext.sessionType,
              let sessionUUID = sessionContext.sessionUUID,
              let isIndoor = sessionContext.isIndoor
        else {
            assertionFailure("invalidCreateSessionContext \(sessionContext)")
            completion(.failure(AirBeamSessionCreatorError.invalidCreateSessionContext(sessionContext)))
            return
        }
        // Save data to app's database
        let session = Session(uuid: sessionUUID,
                              type: sessionType,
                              name: sessionContext.sessionName,
                              deviceType: sessionContext.deviceType,
                              location: sessionContext.startingLocation,
                              startTime: DateBuilder.getFakeUTCDate(),
                              followedAt: DateBuilder.getFakeUTCDate(),
                              isIndoor: isIndoor,
                              tags: sessionContext.sessionTags,
                              status: .FINISHED
        )

        guard let name = session.name,
              let startTime = session.startTime,
              let device = sessionContext.device,
              let wifiSSID = sessionContext.wifiSSID,
              let wifiPassword = sessionContext.wifiPassword,
              let contribute = sessionContext.contribute
        else {
            assertionFailure("invalidCreateSessionContext \(sessionContext)")
            completion(.failure(AirBeamSessionCreatorError.invalidCreateSessionContext(sessionContext)))
            return
        }

        switch device.firmwareVersion {
        case .v2:
            createV2Session(sessionUUID: sessionUUID,
                            session: session,
                            name: name,
                            isIndoor: isIndoor,
                            contribute: contribute,
                            device: device,
                            wifiSSID: wifiSSID,
                            wifiPassword: wifiPassword,
                            completion: completion)
        case .v1:
            createV1Session(sessionUUID: sessionUUID,
                            session: session,
                            name: name,
                            startTime: startTime,
                            isIndoor: isIndoor,
                            contribute: contribute,
                            device: device,
                            wifiSSID: wifiSSID,
                            wifiPassword: wifiPassword,
                            completion: completion)
        }
    }

    private func createV1Session(sessionUUID: SessionUUID,
                                 session: Session,
                                 name: String,
                                 startTime: Date,
                                 isIndoor: Bool,
                                 contribute: Bool,
                                 device: any BluetoothDevice,
                                 wifiSSID: String,
                                 wifiPassword: String,
                                 completion: @escaping (Result<Void, Error>) -> Void) {
        let params = CreateSessionApi.SessionParams(uuid: sessionUUID,
                                                    type: .fixed,
                                                    title: name,
                                                    tag_list: session.tags ?? "",
                                                    start_time: startTime,
                                                    end_time: startTime,
                                                    contribute: contribute,
                                                    is_indoor: isIndoor,
                                                    notes: [],
                                                    version: 0,
                                                    streams: [:],
                                                    latitude: session.location?.latitude,
                                                    longitude: session.location?.longitude)
        createSessionService.createEmptyFixedWifiSession(input: .init(session: params,
                                                                      compression: true),
                                                         completion: { [persistence] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let output):
                    persistence.accessStorage { storage in
                        do {
                            let sessionWithURL = session.withUrlLocation(output.location)
                            try storage.createSession(sessionWithURL)
                            self.uiStore.accessStorage({ storage in
                                storage.giveHighestOrder(to: sessionWithURL.uuid)
                            })
                            Log.info("Created fixed Wifi session \(output)")
                            Resolver.resolve(AirBeamConfigurator.self, args: device)
                                .configureFixedWifiSession(uuid: sessionUUID,
                                                           location: session.location ?? CLLocationCoordinate2D(latitude: 200, longitude: 200),
                                                           date: DateBuilder.getFakeUTCDate(),
                                                           wifiSSID: wifiSSID,
                                                           wifiPassword: wifiPassword) { result in
                                    switch result {
                                    case .success():
                                        Log.info("Successfully configured AB")
                                        completion(.success(()))
                                    case .failure(let error):
                                        Log.error("Failed to configure AB: \(error)")
                                        completion(.failure(error))
                                    }
                                }
                        } catch {
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    Log.warning("Failed to create fixed Wifi session \(error)")
                    completion(.failure(error))
                }
            }
        })
    }

    private func createV2Session(sessionUUID: SessionUUID,
                                 session: Session,
                                 name: String,
                                 isIndoor: Bool,
                                 contribute: Bool,
                                 device: any BluetoothDevice,
                                 wifiSSID: String,
                                 wifiPassword: String,
                                 completion: @escaping (Result<Void, Error>) -> Void) {
        let coordinate = session.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        // iOS has no access to the BLE MAC; CoreBluetooth only exposes a per-app
        // UUID. The BE keys the airbeam record off `mac_address` and uses it to
        // derive `sensor_package_name` — when we sent the raw UUID (e.g.
        // "A81AE1F5-XXXX-…"), the dashboard's session header split it on `-`
        // and rendered the leading hex segment instead of "AirBeamMini". Format
        // the UUID as a colon-separated MAC-like string so the BE takes the
        // colon path Android also exercises and stores a sensor_package_name
        // that includes the model prefix.
        let macAddress = macAddressLike(from: device.uuid)
        let body = V2FixedSessionAPI.RequestBody(
            uuid: sessionUUID.rawValue,
            title: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            contribute: contribute,
            is_indoor: isIndoor,
            airbeam: .init(mac_address: macAddress,
                           model: "AirBeamMini",
                           name: name),
            streams: [
                .init(sensor_name: MeasurementStreamSensorName.mini_pm1.rawValue, unit_symbol: "µg/m³"),
                .init(sensor_name: MeasurementStreamSensorName.mini_pm2_5.rawValue, unit_symbol: "µg/m³"),
            ]
        )

        v2FixedSessionService.createFixedSession(body: body) { [persistence, uiStore, bluetoothConnectionHandler] result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    Log.warning("V2 fixed session POST failed: \(error)")
                    completion(.failure(error))
                case .success(let response):
                    Log.info("V2 fixed session POST response streams: \(response.streams.map { "\($0.sensor_name)=\($0.sensor_type_id)" }.joined(separator: ", ")) location=\(response.location ?? "<nil>")")
                    guard let pm1TypeId = response.streams.first(where: { $0.sensor_name.lowercased().contains("pm1") && !$0.sensor_name.lowercased().contains("pm2") })?.sensor_type_id,
                          let pm25TypeId = response.streams.first(where: { $0.sensor_name.lowercased().contains("pm2") })?.sensor_type_id else {
                        Log.error("V2 fixed session response missing sensor_type_id: \(response.streams.map(\.sensor_name))")
                        completion(.failure(AirBeamSessionCreatorError.missingSensorTypeID))
                        return
                    }
                    Log.info("V2 fixed session resolved pm1_index=\(pm1TypeId) pm25_index=\(pm25TypeId)")
                    persistence.accessStorage { storage in
                        do {
                            let sessionWithURL = session.withUrlLocation(response.location ?? "")
                            try storage.createSession(sessionWithURL)
                            // Stamp firmware version so `SessionEntity.deviceFirmwareVersion`
                            // reports `.v2` for this row — `UpdateSessionParamsService.sessionRequiresUtcShift`
                            // gates the indoor / locationless UTC shift on it (V1 fixed sessions
                            // upload via gzipped JSON and BE's
                            // `skip_time_zone_conversion_for_attributes` already lines up with
                            // iOS's fakeUTC convention, so shifting them double-counts).
                            try storage.stampBluetoothConnection(sessionUUID: sessionUUID,
                                                                 peripheralUUID: device.uuid,
                                                                 firmwareVersion: .v2)
                            uiStore.accessStorage { $0.giveHighestOrder(to: sessionWithURL.uuid) }
                            Log.info("Created V2 fixed session \(sessionUUID.rawValue), token=\(response.session_token)")
                        } catch {
                            Log.error("Failed to persist V2 fixed session: \(error)")
                            completion(.failure(error))
                            return
                        }
                        let configurator = Resolver.resolve(AirBeamMiniV2Configurator.self, args: device)
                        configurator.configureV2FixedSession(uuid: sessionUUID,
                                                             sessionTokenHex: response.session_token,
                                                             pm1Index: UInt8(clamping: pm1TypeId),
                                                             pm25Index: UInt8(clamping: pm25TypeId),
                                                             wifiSSID: wifiSSID,
                                                             wifiPassword: wifiPassword) { configureResult in
                            DispatchQueue.main.async {
                                switch configureResult {
                                case .success:
                                    Log.info("V2 fixed session configured; disconnecting BLE.")
                                    try? bluetoothConnectionHandler.disconnect(from: device)
                                    Resolver.resolve(V2ConfiguratorRegistry.self).release(deviceUUID: device.uuid)
                                    completion(.success(()))
                                case .failure(let error):
                                    Log.error("V2 fixed session configure failed: \(error). Keeping local row for retry.")
                                    completion(.failure(error))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /// Derive a stable MAC-like identifier from the per-app CoreBluetooth UUID.
    /// Format: "XX:XX:XX:XX:XX:XX" (uppercase hex). Uses the last 12 hex chars
    /// of the UUID — they are the most-randomised section.
    private func macAddressLike(from uuid: String) -> String {
        let hex = uuid.replacingOccurrences(of: "-", with: "").uppercased()
        let tail = String(hex.suffix(12)).padding(toLength: 12, withPad: "0", startingAt: 0)
        return stride(from: 0, to: tail.count, by: 2).map {
            let start = tail.index(tail.startIndex, offsetBy: $0)
            let end = tail.index(start, offsetBy: 2)
            return String(tail[start..<end])
        }.joined(separator: ":")
    }
}
