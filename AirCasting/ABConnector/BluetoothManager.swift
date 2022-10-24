//
//  BluetoothManager.swift
//  AirCasting
//
//  Created by Lunar on 02/02/2021.
//

import Foundation
import CoreBluetooth
import Resolver

protocol BluetoothCommunicator {
    typealias CharacteristicObserverAction = (Result<Data?, Error>) -> Void
    
    /// Adds an entry to observers of a particular characteristic
    /// - Parameters:
    ///   - characteristic: UUID of characteristic to observe
    ///   - timeout: a timeout after which the error is produced
    ///   - notify: block called each time characteristic changes (either changes value or throws an error)
    /// - Returns: Opaque token to use when un-registering
    func subscribeToCharacteristic(_ characteristic: CBUUID, timeout: TimeInterval?, notify: @escaping CharacteristicObserverAction) -> AnyHashable
    
    /// Removes an entry from observing characteristic
    /// - Parameter token: Opaque token received on subscription
    /// - Returns: A `Bool` value indicating if a given token was successfuly removed. Only reason it can fail is double unregistration.
    @discardableResult func unsubscribeCharacteristicObserver(_ token: AnyHashable) -> Bool
}

extension BluetoothCommunicator {
    func subscribeToCharacteristic(_ characteristic: CBUUID, notify: @escaping CharacteristicObserverAction) -> AnyHashable {
        subscribeToCharacteristic(characteristic, timeout: nil, notify: notify)
    }
}

class BluetoothManager: NSObject, BluetoothCommunicator, ObservableObject {
    
    lazy var centralManager: CBCentralManager = {
        let centralManager = CBCentralManager()
        centralManager.delegate = self
        isScanning = centralManager.isScanning
        observed = centralManager.observe(\.isScanning) { [weak self] _, change in
            self?.isScanning = self?.centralManager.isScanning ?? false
        }
        return centralManager
    }()

    @Published var devices: [CBPeripheral] = []
    @Published var isScanning: Bool = true
    @Published var centralManagerState: CBManagerState = .unknown
    @Published var mobileSessionReconnected = false
    var observed: NSKeyValueObservation?

    let mobilePeripheralSessionManager: MobilePeripheralSessionManager
    @Injected private var featureFlagProvider: FeatureFlagProvider

    private var MEASUREMENTS_CHARACTERISTIC_UUIDS: [CBUUID] = [
        CBUUID(string:"0000ffe1-0000-1000-8000-00805f9b34fb"),    // Temperature
        CBUUID(string:"0000ffe3-0000-1000-8000-00805f9b34fb"),    // Humidity
        CBUUID(string:"0000ffe4-0000-1000-8000-00805f9b34fb"),    // PM1
        CBUUID(string:"0000ffe5-0000-1000-8000-00805f9b34fb"),    // PM2.5
        CBUUID(string:"0000ffe6-0000-1000-8000-00805f9b34fb")]   // PM10

    // has notifications about measurements count in particular csv file on SD card
    private let DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffde-0000-1000-8000-00805f9b34fb")

    // has notifications for reading measurements stored in csv files on SD card
    private let DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffdf-0000-1000-8000-00805f9b34fb")

    var airbeams: [CBPeripheral] {
        devices.filter { (device) -> Bool in
            device.name?.contains("AirBeam") ?? false
        }
    }
    var otherDevices: [CBPeripheral] {
        devices.filter { (device) -> Bool in
            !(device.name?.contains("AirBeam") ?? false)
        }
    }

    func startScanning() {
        //AirBeam 3 UUID
        //let service = CBUUID(string: "0000ffdd-0000-1000-8000-00805f9b34fb")
        devices = []
        centralManager.scanForPeripherals(withServices: nil,
                                          options: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(30)) { [centralManager] in
            centralManager.stopScan()
        }
    }

    init(mobilePeripheralSessionManager: MobilePeripheralSessionManager) {
        self.mobilePeripheralSessionManager = mobilePeripheralSessionManager
        super.init()
        if CBCentralManager.authorization == .allowedAlways {
            // To avoid the .unknown state of centralManager when bluetooth is poweredOn
            let _ = centralManager
        }
    }

    // MARK: - Refactored part
    // This is the part of this class that is already refactored.
    
    enum CharacteristicObservingError: Error {
        case timeout
    }

    private class CharacteristicObserver {
        let identifier = UUID()
        var triggerCounter = 0
        let action: CharacteristicObserverAction
        
        init(action: @escaping CharacteristicObserverAction) {
            self.action = action
        }
    }
    
    private var charactieristicsMapping: [CBUUID: [CharacteristicObserver]] = [:]
    private let characteristicsMappingLock = NSRecursiveLock()

    func subscribeToCharacteristic(_ characteristic: CBUUID, timeout: TimeInterval? = nil, notify: @escaping CharacteristicObserverAction) -> AnyHashable {
        let observer = CharacteristicObserver(action: notify)
        if let timeout = timeout { scheduleTimeout(timeout, for: observer) }
        characteristicsMappingLock.lock()
        charactieristicsMapping[characteristic, default:[]].append(observer)
        characteristicsMappingLock.unlock()
        return observer.identifier
    }
    
    private func scheduleTimeout(_ timeout: TimeInterval, for observer: CharacteristicObserver) {
        Log.info("Scheduling timeout")
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(Int(timeout * 1000))) {
            self.characteristicsMappingLock.lock()
            defer { self.characteristicsMappingLock.unlock() }
            guard observer.triggerCounter == 0 else { return }
            observer.action(.failure(CharacteristicObservingError.timeout))
        }
    }
    
    @discardableResult func unsubscribeCharacteristicObserver(_ token: AnyHashable) -> Bool {
        guard let uuid = token as? UUID else { return false }
        characteristicsMappingLock.lock(); defer { characteristicsMappingLock.unlock() }
        guard let containgObserver = charactieristicsMapping.first(where: { $1.contains { $0.identifier == uuid } }) else { return false }
        var containingObserverArray = containgObserver.value
        containingObserverArray.removeAll { $0.identifier == uuid }
        charactieristicsMapping[containgObserver.key] = containingObserverArray
        return true
    }
}

struct PeripheralMeasurement {
    let peripheral: CBPeripheral
    let measurementStream: ABMeasurementStream
}

extension BluetoothManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        centralManagerState = central.state

        switch central.state {
        case .unknown:
            Log.info("central.state is .unknown")
        case .resetting:
            Log.info("central.state is .resetting")
        case .unsupported:
            Log.info("central.state is .unsupported")
        case .unauthorized:
            Log.info("central.state is .unauthorized")
        case .poweredOff:
            Log.info("central.state is .poweredOff")
        case .poweredOn:
            Log.info("central.state is .poweredOn")
        @unknown default:
            fatalError()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !devices.contains(peripheral) {
            if peripheral.name != nil {
                devices.append(peripheral)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Here's code for getting data from AB.
        peripheral.delegate = self
        if mobilePeripheralSessionManager.activeSessionInProgressWith(peripheral) {
            var characteristicsHandle: Any?
            Log.info("Reconnected to a peripheral: \(peripheral)")
            characteristicsHandle = NotificationCenter.default.addObserver(forName: .discoveredCharacteristic, object: nil, queue: .main) { notification in
                guard notification.userInfo?[AirCastingNotificationKeys.DiscoveredCharacteristic.peripheralUUID] as! UUID == peripheral.identifier else { return }
                Log.info("Discovered characteristics for reconnected peripheral \(peripheral)")
                self.mobileSessionReconnected = true
                guard let characteristicsHandle = characteristicsHandle else { return }
                NotificationCenter.default.removeObserver(characteristicsHandle)
            }
        } else {
            NotificationCenter.default.post(name: .deviceConnected, object: nil, userInfo: [AirCastingNotificationKeys.DeviceConnected.uuid : peripheral.identifier])
        }
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Log.info("Disconnected peripheral \(peripheral) with error: \(String(describing: error?.localizedDescription))")

        charactieristicsMapping.removeAll()

        guard mobilePeripheralSessionManager.activeSessionInProgressWith(peripheral) else { return }
        mobilePeripheralSessionManager.markActiveSessionAsDisconnected(peripheral: peripheral)
        connect(to: peripheral)
        if checkDeviceSupportFor(feature: .standalone) { timeoutConnection(using: peripheral) }
    }
    
    private func timeoutConnection(using peripheral: CBPeripheral) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(60)) {
            guard peripheral.state != .connected else { return }
            Log.info("Didn't connect with peripheral within 60s. Canceling peripheral connection.")
            self.cancelPeripheralConnection(for: peripheral)
            if self.featureFlagProvider.isFeatureOn(.standaloneMode) ?? false {
                Log.info("Moving session to standalone mode")
                self.mobilePeripheralSessionManager.moveSessionToStandaloneMode(peripheral: peripheral)
            } else {
                self.mobilePeripheralSessionManager.finishSession(for: peripheral, centralManager: self.centralManager)
            }
        }
    }
}

extension BluetoothManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        var hasSomeCharacteristics = false
        if let characteristics = service.characteristics {
            Log.info("Did discover service characteristics\n")
            for characteristic in characteristics {
                if MEASUREMENTS_CHARACTERISTIC_UUIDS.contains(characteristic.uuid) {
                    peripheral.setNotifyValue(true, for: characteristic)
                    hasSomeCharacteristics = true
                }

                if characteristic.uuid == DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID {
                    peripheral.setNotifyValue(true, for: characteristic)
                    hasSomeCharacteristics = true
                }

                if characteristic.uuid == DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID {
                    peripheral.setNotifyValue(true, for: characteristic)
                    hasSomeCharacteristics = true
                }
            }
        }
        hasSomeCharacteristics ? NotificationCenter.default.post(name: .discoveredCharacteristic, object: nil, userInfo: [AirCastingNotificationKeys.DiscoveredCharacteristic.peripheralUUID : peripheral.identifier]) : nil
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else {
            Log.warning("AirBeam sent measurement without value")
            return
        }
        characteristicsMappingLock.lock()
        charactieristicsMapping[characteristic.uuid]?.forEach { observer in
            observer.triggerCounter += 1
            guard error == nil else { observer.action(.failure(error!)); return }
            observer.action(.success(characteristic.value))
        }
        characteristicsMappingLock.unlock()

        // TODO: Refactor code below to not parse measurements in this class at all

        guard characteristic.uuid != DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID,
              characteristic.uuid != DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID else {
            return
        }

        if let parsedMeasurement = parseData(data: value) {
            mobilePeripheralSessionManager.handlePeripheralMeasurement(PeripheralMeasurement(peripheral: peripheral, measurementStream: parsedMeasurement))
        }
    }

    func finishMobileSession(with uuid: SessionUUID) {
        mobilePeripheralSessionManager.finishSession(with: uuid, centralManager: centralManager)
    }

    func enterStandaloneMode(sessionUUID: SessionUUID) {
        mobilePeripheralSessionManager.enterStandaloneMode(sessionUUID: sessionUUID, centralManager: centralManager)
    }

    func parseData(data: Data) -> ABMeasurementStream? {
        let string = String(data: data, encoding: .utf8)
        let components = string?.components(separatedBy: ";")
        guard let values = components,
              values.count == 12,
              let measuredValue = Double(values[0]),
              let thresholdVeryLow = Int(values[7]),
              let thresholdLow = Int(values[8]),
              let thresholdMedium = Int(values[9]),
              let thresholdHigh = Int(values[10]),
              let thresholdVeryHigh = Int(values[11])
        else  {
            Log.warning("Device didn't send expected values")
            return nil
        }
        let newMeasurement = ABMeasurementStream(measuredValue: measuredValue,
                                          packageName: values[1],
                                          sensorName: values[2],
                                          measurementType: values[3],
                                          measurementShortType: values[4],
                                          unitName: values[5],
                                          unitSymbol: values[6],
                                          thresholdVeryLow: thresholdVeryLow,
                                          thresholdLow: thresholdLow,
                                          thresholdMedium: thresholdMedium,
                                          thresholdHigh: thresholdHigh,
                                          thresholdVeryHigh: thresholdVeryHigh)
        return newMeasurement
    }
}
