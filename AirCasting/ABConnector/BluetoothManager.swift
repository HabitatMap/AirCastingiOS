//
//  BluetoothManager.swift
//  AirCasting
//
//  Created by Lunar on 02/02/2021.
//

import Foundation
import CoreBluetooth
import FirebaseCrashlytics

class BluetoothManager: NSObject, ObservableObject {

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

    typealias CharacteristicObserverAction = (Result<Data?, Error>) -> Void

    private struct CharacteristicObserver {
        let identifier = UUID()
        let action: CharacteristicObserverAction
    }

    // The mapping is CBUUID -> CharacteristicObserver
    // and not UUID(observation token) -> CharacteristicObserver
    // because we care more about the update performance than un-register performance.
    private var charactieristicsMapping: [CBUUID: [CharacteristicObserver]] = [:]
    private let characteristicsMappingLock = NSRecursiveLock()

    /// Adds an entry to observers of a particular characteristic
    /// - Parameters:
    ///   - characteristic: UUID of characteristic to observe
    ///   - notify: block called each time characteristic changes (either changes value or throws an error)
    /// - Returns: Opaque token to use when un-registering
    func subscribeToCharacteristic(_ characteristic: CBUUID, notify: @escaping CharacteristicObserverAction) -> AnyHashable {
        let observer = CharacteristicObserver(action: notify)
        characteristicsMappingLock.lock()
        charactieristicsMapping[characteristic, default:[]].append(observer)
        characteristicsMappingLock.unlock()
        return observer.identifier
    }

    /// Removes an entry from observing characteristic
    /// - Parameter token: Opaque token received on subscription
    /// - Returns: A `Bool` value indicating if a given token was successfuly removed. Only reason it can fail is double unregistration.
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
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
        @unknown default:
            fatalError()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !devices.contains(peripheral) {
            if peripheral.name != nil {
                guard !mobilePeripheralSessionManager.standaloneSessionInProgressWith(peripheral) else { return }
                devices.append(peripheral)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Here's code for getting data from AB.
        peripheral.delegate = self
        if mobilePeripheralSessionManager.activeSessionInProgressWith(peripheral) {
            var characteristicsHandle: Any?
            characteristicsHandle = NotificationCenter.default.addObserver(forName: .discoveredCharacteristic, object: nil, queue: .main) { notification in
                guard notification.userInfo?[AirCastingNotificationKeys.DiscoveredCharacteristic.peripheralUUID] as! UUID == peripheral.identifier else { return }
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
        Log.info("Disconnected: \(String(describing: error?.localizedDescription))")

        charactieristicsMapping.removeAll()

        guard mobilePeripheralSessionManager.activeSessionInProgressWith(peripheral) else { return }
        mobilePeripheralSessionManager.markActiveSessionAsDisconnected(peripheral: peripheral)
        connect(to: peripheral)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
            guard peripheral.state != .connected else { return }
            self.cancelPeripheralConnection(for: peripheral)
            if FeatureFlagsViewModel.shared.enabledFeatures.contains(.standaloneMode) {
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
            Crashlytics.crashlytics().log("BluetoothManager (didDiscoverCharacteristicsFor) - service characteristics\n \(String(describing: service.characteristics))")
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
        charactieristicsMapping[characteristic.uuid]?.forEach { block in
            guard error == nil else { block.action(.failure(error!)); return }
            block.action(.success(characteristic.value))
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
