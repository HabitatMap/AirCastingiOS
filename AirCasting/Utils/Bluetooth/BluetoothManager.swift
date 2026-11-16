// Created by Lunar on 26/10/2022.
//

import Foundation
import CoreBluetooth
import Resolver

private let v2ServiceCBUUID = CBUUID(string: "a0e1f000-0001-4b3c-8e9a-1f2d3c4b5a60")

public enum BluetoothDeviceAuthorizationState {
    case notDetermined
    case denied
    case restricted
    case allowedAlways
}

final class BluetoothManager: NSObject, BluetoothCommunicator, CBCentralManagerDelegate, CBPeripheralDelegate {
    lazy private var centralManager: CBCentralManager = {
        let centralManager = CBCentralManager()
        centralManager.delegate = self
        return centralManager
    }()
    
    private var queue = DispatchQueue(label: "bluetooth.driver.queue")
    
    override init() {
        super.init()
        if CBCentralManager.authorization == .allowedAlways {
            // To avoid the .unknown state of centralManager when bluetooth is poweredOn
            let _ = centralManager
        }
    }
    
    // MARK: Central manager state
    private(set) var deviceState: BluetoothDeviceState = .unknown
    var authorizationState: BluetoothDeviceAuthorizationState {
        get {
            switch CBCentralManager.authorization {
            case .notDetermined:
                return .notDetermined
            case .restricted:
                return .restricted
            case .denied:
                return .denied
            case .allowedAlways:
                return .allowedAlways
            @unknown default:
                return .notDetermined
            }
        }
    }
    
    func isBluetoothDenied() -> Bool {
        CBCentralManager.authorization != .allowedAlways || deviceState != .poweredOn
    }
    
    func forceBluetoothPermissionPopup() {
        // The BT permissions popup shows whenever CBCentralManager is created
        // so we force it here.
        _ = centralManager
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            Log.info("central.state is .unknown")
            deviceState = .unknown
        case .resetting:
            Log.info("central.state is .resetting")
            deviceState = .resetting
            notifyConnectedAsDisconnected()
        case .unsupported:
            Log.info("central.state is .unsupported")
            deviceState = .unsupported
        case .unauthorized:
            Log.info("central.state is .unauthorized")
            deviceState = .unauthorized
        case .poweredOff:
            Log.info("central.state is .poweredOff")
            deviceState = .poweredOff
            // Toggling BT off does not fire didDisconnectPeripheral for connected
            // peripherals — synthesize a disconnect for each tracked peripheral so
            // the reconnection controller's retry loop kicks in and the active
            // session card flips to DISCONNECTED.
            notifyConnectedAsDisconnected()
        case .poweredOn:
            Log.info("central.state is .poweredOn")
            deviceState = .poweredOn
        @unknown default:
            fatalError()
        }
    }

    private func notifyConnectedAsDisconnected() {
        queue.async {
            let snapshot = self.trackedConnectedPeripherals
            guard !snapshot.isEmpty else { return }
            Log.info("BT central went down; synthesizing disconnect for \(snapshot.count) tracked peripheral(s)")
            for peripheral in snapshot {
                let version = self.firmwareVersion(for: peripheral)
                self.callConnectionObserversWithDisconnect(for: self.makeDevice(for: peripheral, firmwareVersion: version))
            }
            self.trackedConnectedPeripherals.removeAll()
        }
    }
    
    // MARK: Scanning
    
    private typealias DiscoveryCallback = (Device) -> Void
    private var deviceDiscoveryCallbacks: [DiscoveryCallback] = []

    private var firmwareVersionByPeripheral: [CBPeripheral: FirmwareVersion] = [:]
    private let firmwareVersionLock = NSRecursiveLock()

    private func firmwareVersion(for peripheral: CBPeripheral) -> FirmwareVersion {
        firmwareVersionLock.lock(); defer { firmwareVersionLock.unlock() }
        return firmwareVersionByPeripheral[peripheral] ?? .v1
    }

    fileprivate func setFirmwareVersion(_ version: FirmwareVersion, for peripheral: CBPeripheral) {
        firmwareVersionLock.lock(); defer { firmwareVersionLock.unlock() }
        firmwareVersionByPeripheral[peripheral] = version
    }

    func refreshedDevice(for device: any BluetoothDevice) -> any BluetoothDevice {
        guard let device = device as? Device else { return device }
        let resolved = firmwareVersion(for: device.peripheral)
        let refreshed = makeDevice(for: device.peripheral,
                                   firmwareVersion: resolved,
                                   rawAdvertisedName: device.name)
        if resolved != device.firmwareVersion || refreshed.name != device.name || refreshed.realMacAddress != device.realMacAddress {
            Log.info("Refreshed device \(device.uuid) fw=\(device.firmwareVersion)->\(resolved) name=\(device.name ?? "nil")->\(refreshed.name ?? "nil")")
        }
        return refreshed
    }

    private struct Device: BluetoothDevice {
        fileprivate let peripheral: CBPeripheral
        var name: String?
        var uuid: String
        var firmwareVersion: FirmwareVersion
        var realMacAddress: String?

        init(peripheral: CBPeripheral, firmwareVersion: FirmwareVersion = .v1, advertisedName: String? = nil, realMacAddress: String? = nil) {
            self.peripheral = peripheral
            // Prefer advertisedName from CBAdvertisementDataLocalNameKey: peripheral.name is
            // often nil at didDiscover time and only filled in once the device has been
            // connected or its GAP name characteristic read. Falling back kept airbeams out
            // of the SelectPeripheral list when iOS hadn't cached the name yet.
            let candidateName = advertisedName ?? peripheral.name
            if let parsed = BluetoothManager.parseAirBeamMiniAdvertisedName(candidateName) {
                name = parsed.normalizedName
                self.realMacAddress = realMacAddress ?? parsed.macAddress
            } else {
                name = candidateName
                self.realMacAddress = realMacAddress
            }
            uuid = peripheral.identifier.description
            self.firmwareVersion = firmwareVersion
        }
    }

    /// Best-known advertised local name per peripheral. V2 AirBeams emit two
    /// packets: a pure advert with no local name, then a scan-response containing
    /// `AirBeamMini:<MAC>`. iOS calls didDiscover for both — cache the richer one
    /// so subsequent ad-only packets don't drop us back to a missing name.
    private static let persistedLocalNamesKey = "bt.lastKnownLocalNameByPeripheralUUID"
    private var lastKnownLocalName: [UUID: String] = [:]
    private let lastKnownLocalNameLock = NSRecursiveLock()

    private func cachedLocalName(for peripheral: CBPeripheral) -> String? {
        lastKnownLocalNameLock.lock(); defer { lastKnownLocalNameLock.unlock() }
        if let inMemory = lastKnownLocalName[peripheral.identifier] {
            return inMemory
        }
        if let persisted = (UserDefaults.standard.dictionary(forKey: Self.persistedLocalNamesKey) as? [String: String])?[peripheral.identifier.uuidString] {
            lastKnownLocalName[peripheral.identifier] = persisted
            return persisted
        }
        return nil
    }

    private func setCachedLocalName(_ name: String, for peripheral: CBPeripheral) {
        lastKnownLocalNameLock.lock(); defer { lastKnownLocalNameLock.unlock() }
        if let existing = lastKnownLocalName[peripheral.identifier],
           Self.parseAirBeamMiniAdvertisedName(existing) != nil,
           Self.parseAirBeamMiniAdvertisedName(name) == nil {
            return
        }
        let normalizedToCache = Self.parseAirBeamMiniAdvertisedName(name)?.normalizedName ?? name
        lastKnownLocalName[peripheral.identifier] = normalizedToCache
        if Self.parseAirBeamMiniAdvertisedName(normalizedToCache) != nil {
            var dict = (UserDefaults.standard.dictionary(forKey: Self.persistedLocalNamesKey) as? [String: String]) ?? [:]
            if dict[peripheral.identifier.uuidString] != normalizedToCache {
                dict[peripheral.identifier.uuidString] = normalizedToCache
                UserDefaults.standard.set(dict, forKey: Self.persistedLocalNamesKey)
            }
        }
    }

    private func makeDevice(for peripheral: CBPeripheral,
                            firmwareVersion: FirmwareVersion,
                            rawAdvertisedName: String? = nil) -> Device {
        if let raw = rawAdvertisedName, !raw.isEmpty {
            setCachedLocalName(raw, for: peripheral)
        }
        let cachedName = cachedLocalName(for: peripheral)
        let candidateName: String?
        if Self.parseAirBeamMiniAdvertisedName(rawAdvertisedName) != nil {
            candidateName = rawAdvertisedName
        } else if Self.parseAirBeamMiniAdvertisedName(cachedName) != nil {
            candidateName = cachedName
        } else if Self.parseAirBeamMiniAdvertisedName(peripheral.name) != nil {
            candidateName = peripheral.name
        } else {
            candidateName = rawAdvertisedName ?? cachedName ?? peripheral.name
        }

        let advertisedName: String?
        let realMac: String?
        if let parsed = Self.parseAirBeamMiniAdvertisedName(candidateName) {
            advertisedName = parsed.normalizedName
            realMac = parsed.macAddress
        } else {
            advertisedName = candidateName
            realMac = nil
        }

        return Device(peripheral: peripheral,
                      firmwareVersion: firmwareVersion,
                      advertisedName: advertisedName,
                      realMacAddress: realMac)
    }

    /// Parse a BLE device name containing `:` and normalize 1.0.0 AirBeamMini names:
    /// - `AirBeamMini:A2:34:56:78:A1` (V2 1.0.0, multiple colons) -> strips colons,
    ///   subtracts 2 from the 48-bit MAC, and returns `("AirBeamMini:A23456789F", "A23456789F")`.
    /// - `AirBeamMini:A23456789E` (V2 1.0.1, single colon) -> kept untouched as
    ///   `("AirBeamMini:A23456789E", "A23456789E")`.
    /// - `AirBeamMini:a23456789e` (V1 ABM, single colon) -> kept untouched as
    ///   `("AirBeamMini:a23456789e", "a23456789e")`.
    /// - `AirBeam3:a23456789e` (AB3, single colon) -> kept untouched as
    ///   `("AirBeam3:a23456789e", "a23456789e")`.
    static func parseAirBeamMiniAdvertisedName(_ name: String?) -> (normalizedName: String, macAddress: String)? {
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty,
              let firstColon = name.firstIndex(of: ":") else { return nil }
        let prefix = String(name[..<firstColon])
        let afterFirstColon = String(name[name.index(after: firstColon)...])
        let colonCount = name.filter { $0 == ":" }.count
        let hex12Pattern = #"^[0-9A-Fa-f]{12}$"#

        if colonCount > 1 {
            // Only normalize 1.0.0 AirBeamMini names (`AirBeamMini:XX:XX:XX:XX:XX:XX`)
            guard prefix.lowercased() == "airbeammini" else { return nil }
            let cleanHex = afterFirstColon.replacingOccurrences(of: ":", with: "")
            guard cleanHex.range(of: hex12Pattern, options: .regularExpression) != nil,
                  let macValue = UInt64(cleanHex, radix: 16) else { return nil }
            let adjustedValue = macValue >= 2 ? (macValue - 2) : 0
            let adjustedMac = String(format: "%012llX", adjustedValue)
            return (normalizedName: "AirBeamMini:\(adjustedMac)", macAddress: adjustedMac)
        } else {
            guard afterFirstColon.range(of: hex12Pattern, options: .regularExpression) != nil else { return nil }
            let canonicalPrefix = prefix.lowercased() == "airbeammini" ? "AirBeamMini" : prefix
            return (normalizedName: "\(canonicalPrefix):\(afterFirstColon)", macAddress: afterFirstColon)
        }
    }
    
    func startScanning(scanningWindow: Int = 30,
                       onDeviceDiscovered: @escaping (any BluetoothDevice) -> Void,
                       onScanningFinished: (() -> Void)?) {
        queue.async {
            Log.verbose("Started scanning for BT devices with scanning time: \(scanningWindow)s")
            self.deviceDiscoveryCallbacks.append(onDeviceDiscovered)
            self.centralManager.scanForPeripherals(withServices: nil,
                                              options: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(scanningWindow)) {
                self.queue.async {
                    Log.verbose("Stopping scanning for BT devices")
                    self.centralManager.stopScan()
                    self.callbackQueue.async { onScanningFinished?() }
                }
            }
        }
    }
    
    func stopScan() {
        if centralManager.isScanning {
            centralManager.stopScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let advertisedServices = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        let detected: FirmwareVersion = advertisedServices.contains(v2ServiceCBUUID) ? .v2 : .v1
        // Promote to .v2 when advertisement says so; never downgrade an already-confirmed v2.
        let stored = firmwareVersion(for: peripheral)
        let resolved: FirmwareVersion = (stored == .v2 || detected == .v2) ? .v2 : .v1
        if resolved == .v2 && stored != .v2 { setFirmwareVersion(.v2, for: peripheral) }

        let rawAdvertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let device = makeDevice(for: peripheral,
                                firmwareVersion: resolved,
                                rawAdvertisedName: rawAdvertisedName)
        if resolved == .v2, device.realMacAddress != nil {
            Resolver.resolve(V2ConfiguratorRegistry.self).updateIfPresent(device: device)
        }

        queue.async {
            self.deviceDiscoveryCallbacks.forEach { callback in
                self.callbackQueue.async {
                    callback(device)
                }
            }
        }
    }
    
    // MARK: Connection Observers
    
    private var callbackQueue = DispatchQueue(label: "bluetooth.driver.callback.queue")
    private var connectionObservers: [BluetoothConnectionObserver] = []
    /// Peripherals we have an active connection to. Needed so we can synthesize
    /// disconnect events when the central goes `.poweredOff` (e.g., user toggles
    /// BT off on the phone) — CoreBluetooth does not fire didDisconnect in that case.
    private var trackedConnectedPeripherals: Set<CBPeripheral> = []
    
    func addConnectionObserver(_ observer: BluetoothConnectionObserver) {
        queue.async {
            self.connectionObservers.append(observer)
        }
    }
    
    func removeConnectionObserver(_ observer: BluetoothConnectionObserver) {
        queue.async {
            self.connectionObservers.removeAll(where: { $0 === observer })
        }
    }
    
    private func callConnectionObserversWithDisconnect(for device: Device) {
        self.connectionObservers.forEach { observer in
            callbackQueue.async { observer.didDisconnect(device: device) }
        }
    }
    
    
    // MARK: Connecting
    typealias ConnectionCallback = (Result<Void, Error>) -> Void
    private var connectionCallbacks: [CBPeripheral: [ConnectionCallback]] = [:]
    
    enum BluetoothDriverError: Error {
        case timeout
        case deviceBusy
        case unknown
        /// The requested service/characteristic was not found on the peripheral
        /// (e.g. a v2 device routed into the v1 configurator looks up a service it
        /// does not expose). Surfaced instead of silently returning so the caller's
        /// completion fails and the reconnect chain can retry rather than hang.
        case characteristicNotFound
    }
    
    func connect(to device: any BluetoothDevice, timeout: TimeInterval, completion: @escaping ConnectionCallback) throws {
        guard let device = device as? Device else { Log.error("BluetoothManager received unexpected device type (expected BluetooothManager.Device, received \(type(of: device))"); throw WrongDeviceType()}
        queue.async {
            Log.verbose("Starting connection to BT device \(device.peripheral.name ?? "unnamed")")
            guard !(device.peripheral.state == .connecting) else {
                completion(.failure(BluetoothDriverError.deviceBusy))
                return
            }
            
            self.connectionCallbacks[device.peripheral, default: []].append(completion)
            self.centralManager.connect(device.peripheral)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                self.queue.async {
                    guard !(self.connectionCallbacks[device.peripheral]?.isEmpty ?? true) else {
                        return
                    }
                    Log.verbose("Connection timed out for BT device \(device.peripheral.name ?? "unnamed")")
                    self.centralManager.cancelPeripheralConnection(device.peripheral)
                    self.connectionCallbacks[device.peripheral] = []
                    self.callbackQueue.async { completion(.failure(BluetoothDriverError.timeout)) }
                    
                }
            }
        }
    }
    
    func disconnect(from device: any BluetoothDevice) throws {
        guard let device = device as? Device else { Log.error("BluetoothManager received unexpected device type (expected BluetooothManager.Device, received \(type(of: device))"); throw WrongDeviceType()}
        self.centralManager.cancelPeripheralConnection(device.peripheral)
    }
    
    func discoverCharacteristics(for device: any BluetoothDevice,
                                 timeout: TimeInterval,
                                 completion: @escaping CharacteristicsDicoveryCallback) throws {
        guard let device = device as? Device else { Log.error("BluetoothManager received unexpected device type (expected BluetooothManager.Device, received \(type(of: device))"); throw WrongDeviceType()}
        queue.async {
            device.peripheral.discoverServices(nil)
            self.characteristicsDicoveryCallbacks[device.peripheral, default: []].append(completion)
            self.scheduleCharacteristicsDiscoveryTimeout(timeout, for: device.peripheral)
        }
    }
    
    struct WrongDeviceType: Error {}
    
    func isDeviceConnected(device: any BluetoothDevice) throws -> Bool {
        guard let device = device as? Device else { Log.error("BluetoothManager received unexpected device type (expected BluetooothManager.Device, received \(type(of: device))"); throw WrongDeviceType()}
        return device.peripheral.state == .connected
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        queue.async {
            Log.verbose("Did connect to BT device \(peripheral.name ?? "unnamed")")
            peripheral.delegate = self
            self.trackedConnectedPeripherals.insert(peripheral)
            guard let callbacks = self.connectionCallbacks[peripheral] else {
                return
            }
            callbacks.forEach { callback in
                self.callbackQueue.async { callback(.success(())) }
            }
            self.connectionCallbacks[peripheral] = []
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        queue.async {
            Log.info("Failed to connect to device [\(peripheral.name ?? "unnamed")]: \(error?.localizedDescription ?? "No error")")
            guard let callbacks = self.connectionCallbacks[peripheral] else {
                return
            }
            callbacks.forEach { callback in
                self.callbackQueue.async { callback(.failure(error ?? BluetoothDriverError.unknown)) }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Log.info("Disconnected peripheral \(peripheral) with error: \(String(describing: error?.localizedDescription))")
        let version = firmwareVersion(for: peripheral)
        queue.async {
            self.trackedConnectedPeripherals.remove(peripheral)
            self.callConnectionObserversWithDisconnect(for: self.makeDevice(for: peripheral, firmwareVersion: version))
        }
    }
    
    // MARK: Characteristics
    
    struct BluetoothCharacteristic {
        let UUID: String
    }
    
    enum CharacteristicObservingError: Error {
        case timeout
    }
    
    enum CharacteristicsDiscoveryError: Error {
        case timeout
    }
    
    private class CharacteristicObserver {
        let identifier = UUID()
        var triggerCounter = 0
        var device: Device
        let action: CharacteristicObserverAction
        
        init(action: @escaping CharacteristicObserverAction, device: Device) {
            self.action = action
            self.device = device
        }
    }
    
    private var charactieristicsMapping: [CharacteristicUUID: [CharacteristicObserver]] = [:]
    private let characteristicsMappingLock = NSRecursiveLock()
    typealias CharacteristicsDicoveryCallback = (Result<[BluetoothCharacteristic], Error>) -> Void
    private var characteristicsDicoveryCallbacks: [CBPeripheral: [CharacteristicsDicoveryCallback]] = [:]
    
    private func scheduleCharacteristicsDiscoveryTimeout(_ timeout: TimeInterval, for peripheral: CBPeripheral) {
        Log.info("Scheduling timeout")
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            self.queue.async {
                guard let callbacks = self.characteristicsDicoveryCallbacks[peripheral] else { return }
                guard !callbacks.isEmpty else { return }
                callbacks.forEach { callback in
                    self.callbackQueue.async { callback(.failure(CharacteristicsDiscoveryError.timeout)) }
                }
                self.characteristicsDicoveryCallbacks[peripheral] = []
            }
        }
    }
    
    func subscribeToCharacteristic(for device: any BluetoothDevice,
                                   characteristic: CharacteristicUUID,
                                   timeout: TimeInterval? = nil,
                                   notify: @escaping CharacteristicObserverAction) throws -> AnyHashable {
        guard let device = device as? Device else { Log.error("BluetoothManager received unexpected device type (expected BluetooothManager.Device, received \(type(of: device))"); throw WrongDeviceType()}
        let observer = CharacteristicObserver(action: notify, device: device)
        if let timeout = timeout { scheduleTimeout(timeout, for: observer) }
        characteristicsMappingLock.lock()
        charactieristicsMapping[characteristic, default:[]].append(observer)
        characteristicsMappingLock.unlock()
        device.peripheral.services?.forEach {
            let allMatching = $0.characteristics?.filter { $0.uuid == CBUUID(string: characteristic.value) } ?? []
            allMatching.forEach {
                device.peripheral.setNotifyValue(true, for: $0)
            }
        }
        if device.peripheral.services == nil {
            Log.error("Tried to subscibe to characteristics before they were discovered")
        }
        return observer.identifier
    }
    
    @discardableResult func unsubscribeCharacteristicObserver(token: AnyHashable) -> Bool {
        guard let uuid = token as? UUID else { return false }
        characteristicsMappingLock.lock(); defer { characteristicsMappingLock.unlock() }
        guard let containgObserver = charactieristicsMapping.first(where: { $1.contains { $0.identifier == uuid } }) else { return false }
        var containingObserverArray = containgObserver.value
        let device = containingObserverArray.first?.device
        containingObserverArray.removeAll { $0.identifier == uuid }
        let characteristic = containgObserver.key
        charactieristicsMapping[characteristic] = containingObserverArray
        // If last subscriber unssubbed, stop notifying
        if containingObserverArray.isEmpty && device?.peripheral.state == .connected {
            device?.peripheral.services?.forEach {
                let allMatching = $0.characteristics?.filter { $0.uuid == CBUUID(string: characteristic.value) } ?? []
                allMatching.forEach { device?.peripheral.setNotifyValue(false, for: $0) }
            }
        }
        return true
    }
    
    private func scheduleTimeout(_ timeout: TimeInterval, for observer: CharacteristicObserver) {
        Log.info("Scheduling timeout")
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(Int(timeout * 1000))) {
            self.characteristicsMappingLock.lock()
            defer { self.characteristicsMappingLock.unlock() }
            guard observer.triggerCounter == 0 else { return }
            self.callbackQueue.async { observer.action(.failure(CharacteristicObservingError.timeout)) }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services,
           services.contains(where: { $0.uuid == v2ServiceCBUUID }) {
            // Connection-time confirmation: stamp v2 once GATT discovery proves the V2 service is present.
            setFirmwareVersion(.v2, for: peripheral)
        }
        queue.async {
            if let services = peripheral.services {
                for service in services {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            Log.info("Did discover service characteristics\n")
            for characteristic in characteristics {
                guard charactieristicsMapping.keys.contains(where: { CBUUID(string: $0.value) == characteristic.uuid }) else { continue }
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
        characteristicsDicoveryCallbacks[peripheral]?.forEach { callback in
            let characteristics = peripheral.services?.compactMap(\.characteristics).compactMap { $0 }.flatMap({$0}) ?? []
            callbackQueue.async {
                callback(.success(characteristics.map({BluetoothCharacteristic(UUID: $0.uuid.uuidString )})))
            }
        }
        characteristicsDicoveryCallbacks.removeValue(forKey: peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            Log.error("[SD Sync] \(String(describing: error))")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let value = characteristic.value
        characteristicsMappingLock.lock()
        defer { characteristicsMappingLock.unlock()}
        guard let containgObserver = charactieristicsMapping.first(where: { CBUUID(string: $0.key.value) == characteristic.uuid }) else { return }
        containgObserver.value.forEach { observer in
            observer.triggerCounter += 1
            guard error == nil else { observer.action(.failure(error!)); return }
            callbackQueue.async { observer.action(.success(value)) }
        }
    }
    
    // MARK: Writing values
    
    typealias writingValueCallback = (Result<Void, Error>) -> Void
    private var writingValueCallbacks: [CBCharacteristic: [writingValueCallback]] = [:]
    
    func sendMessage(data: Data, to device: any BluetoothDevice, serviceID: String, characteristicID: String, completion: @escaping writingValueCallback) throws {
        guard let device = device as? Device else { Log.error("BluetoothManager received unexpected device type (expected BluetooothManager.Device, received \(type(of: device))"); throw WrongDeviceType()}
        let serviceUUID = CBUUID(string: serviceID)
        let characteristicUUID = CBUUID(string: characteristicID)
        guard let characteristic = getCharacteristic(serviceID: serviceUUID,
                                                     charID: characteristicUUID,
                                                     peripheral: device.peripheral) else {
            Log.error("Unable to get characteristic from \(String(describing: device.peripheral)) — failing send (service=\(serviceID) char=\(characteristicID))")
            // Fail loud instead of silently returning. A silent return left the
            // configurator's write completion unfulfilled, so the reconnect chain
            // hung forever ("AB connected / app disconnected") instead of erroring
            // and retrying.
            callbackQueue.async { completion(.failure(BluetoothDriverError.characteristicNotFound)) }
            return
        }
        Log.info("Writing value to peripheral")
        
        queue.async {
            self.writingValueCallbacks[characteristic, default: []].append(completion)
            device.peripheral.writeValue(data,
                                         for: characteristic,
                                         type: .withResponse)
        }
    }
    
    
    
    private func getCharacteristic(serviceID: CBUUID, charID: CBUUID, peripheral: CBPeripheral) -> CBCharacteristic? {
        Log.info("Getting characteristics for peripheral. Peripheral services: \(String(describing: peripheral.services?.count))")
        let service = peripheral.services?.first(where: { data -> Bool in
            data.uuid == serviceID
        })
        Log.info("Service characteristics: \(String(describing: service?.characteristics?.count))")
        guard let characteristic = service?.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == charID
        }) else {
            return nil
        }
        return characteristic
    }
    
    func readValue(for device: any BluetoothDevice, serviceID: String, characteristicID: String) throws {
        guard let device = device as? Device else { Log.error("BluetoothManager received unexpected device type"); throw WrongDeviceType() }
        let serviceUUID = CBUUID(string: serviceID)
        let characteristicUUID = CBUUID(string: characteristicID)
        guard let characteristic = getCharacteristic(serviceID: serviceUUID,
                                                     charID: characteristicUUID,
                                                     peripheral: device.peripheral) else {
            Log.error("Unable to read value: characteristic \(characteristicID) not found")
            throw BluetoothDriverError.characteristicNotFound
        }
        queue.async {
            device.peripheral.readValue(for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        queue.async {
            Log.verbose("Did write value for characteristic: \(characteristic), error: \(String(describing: error))")
            self.writingValueCallbacks[characteristic]?.forEach { error == nil ? $0(.success(())) : $0(.failure(error!)) }
            self.writingValueCallbacks[characteristic] = nil
        }
        
    }
}
