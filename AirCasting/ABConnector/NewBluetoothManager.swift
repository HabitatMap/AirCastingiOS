// Created by Lunar on 26/10/2022.
//

import Foundation
import CoreBluetooth
import Resolver

public enum BluetoothDeviceAuthorizationState {
    case notDetermined
    case denied
    case allowedAlways
}

// TODO: Naming
protocol BluetoothStateHandler {
    var authorizationState: BluetoothDeviceAuthorizationState { get }
    var deviceState: BluetoothDeviceState { get }
    func forceBluetoothPermissionPopup()
}

protocol BluetoothConnectionObserver: AnyObject {
    func didDisconnect(device: NewBluetoothManager.BluetoothDevice)
}

final class NewBluetoothManager: NSObject, NewBluetoothCommunicator, CBCentralManagerDelegate, CBPeripheralDelegate {
    // TODO: Make it private when the rest of the codebase is transformed to not use CB
    lazy var centralManager: CBCentralManager = {
        let centralManager = CBCentralManager()
        centralManager.delegate = self
        return centralManager
    }()
    
    private var queue = DispatchQueue(label: "bluetooth.driver.queue")
    
    func forceBluetoothPermissionPopup() {
        // The BT permissions popup shows whenever CBCentralManager is created
        // so we force it here.
        _ = centralManager
    }
    
    // MARK: Observers
    
    private var callbackQueue = DispatchQueue(label: "bluetooth.driver.callback.queue")
    private var connectionObservers: [BluetoothConnectionObserver] = []
    
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
    
    private func callConnectionObserversWithDisconnect(for device: BluetoothDevice) {
        self.connectionObservers.forEach { observer in
            callbackQueue.async { observer.didDisconnect(device: device) }
        }
    }
    
    // MARK: Scanning
    
    private typealias DiscoveryCallback = (BluetoothDevice) -> Void
    private var deviceDiscoveryCallbacks: [DiscoveryCallback] = []
    
    class BluetoothDevice: Equatable {
//        fileprivate let peripheral: CBPeripheral COMMENTED OUT JUST TEMPORARILY
        let peripheral: CBPeripheral
        let id = UUID()
        var name: String?
        var uuid: String
        
        static func == (lhs: NewBluetoothManager.BluetoothDevice, rhs: NewBluetoothManager.BluetoothDevice) -> Bool {
            lhs.peripheral == rhs.peripheral
        }
        
        init(peripheral: CBPeripheral) {
            self.peripheral = peripheral
            name = peripheral.name
            uuid = peripheral.identifier.description
        }
    }
    
    func startScanning(scanningWindow: Int = 30,
                       onDeviceDiscovered: @escaping (BluetoothDevice) -> Void,
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
        queue.async {
            Log.verbose("Did discover BT device \(peripheral.name ?? "unnamed")")
            self.deviceDiscoveryCallbacks.forEach { callback in
                self.callbackQueue.async { callback(BluetoothDevice(peripheral: peripheral)) }
            }
        }
    }
    
    // MARK: Connecting
    typealias ConnectionCallback = (Result<Void, Error>) -> Void
    private var connectionCallbacks: [CBPeripheral: [ConnectionCallback]] = [:]
    
    enum BluetoothDriverError: Error {
        case timeout
        case unknown
    }
    
    func connect(to device: BluetoothDevice, timeout: TimeInterval, completion: @escaping ConnectionCallback) {
        queue.async {
            Log.verbose("Starting connection to BT device \(device.peripheral.name ?? "unnamed")")
            self.connectionCallbacks[device.peripheral, default: []].append(completion)
            self.centralManager.connect(device.peripheral)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                self.queue.async {
                    guard !(self.connectionCallbacks[device.peripheral]?.isEmpty ?? true) else {
                        return
                    }
                    Log.verbose("Connection timed out for BT device \(device.peripheral.name ?? "unnamed")")
                    self.connectionCallbacks[device.peripheral] = []
                    self.callbackQueue.async { completion(.failure(BluetoothDriverError.timeout)) }
                    
                }
            }
        }
    }
    
    func disconnect(from device: BluetoothDevice) {
        self.centralManager.cancelPeripheralConnection(device.peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        queue.async {
            Log.verbose("Did connect to BT device \(peripheral.name ?? "unnamed")")
            peripheral.delegate = self
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
        queue.async {
            self.callConnectionObserversWithDisconnect(for: .init(peripheral: peripheral))
        }
    }
    
    // MARK: Characteristics
    
    struct BluetoothCharacteristic {
        let device: BluetoothDevice
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
        var device: BluetoothDevice
        let action: CharacteristicObserverAction
        
        init(action: @escaping CharacteristicObserverAction, device: BluetoothDevice) {
            self.action = action
            self.device = device
        }
    }
    
    private var charactieristicsMapping: [CharacteristicUUID: [CharacteristicObserver]] = [:]
    private let characteristicsMappingLock = NSRecursiveLock()
    typealias CharacteristicsDicoveryCallback = (Result<[BluetoothCharacteristic], Error>) -> Void
    private var characteristicsDicoveryCallbacks: [CBPeripheral: [CharacteristicsDicoveryCallback]] = [:]
    
    func discoverCharacteristics(for device: BluetoothDevice,
                                 timeout: TimeInterval,
                                 completion: @escaping CharacteristicsDicoveryCallback) {
        queue.async {
            device.peripheral.discoverServices(nil)
            self.characteristicsDicoveryCallbacks[device.peripheral, default: []].append(completion)
            self.scheduleCharacteristicsDiscoveryTimeout(timeout, for: device.peripheral)
        }
    }
    
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
    
    func subscribeToCharacteristic(for device: BluetoothDevice,
                                   characteristic: CharacteristicUUID,
                                   timeout: TimeInterval? = nil,
                                   notify: @escaping CharacteristicObserverAction) -> AnyHashable {
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
            device.peripheral.discoverServices(nil)
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
        if containingObserverArray.isEmpty {
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
            let characteristics = peripheral.services?.compactMap(\.characteristics).compactMap { $0 }
            callbackQueue.async {
                callback(.success([.init(device: BluetoothDevice(peripheral: peripheral))])) // Fix with Paweł
            }
        }
        characteristicsDicoveryCallbacks.removeValue(forKey: peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        characteristicsMappingLock.lock()
        defer { characteristicsMappingLock.unlock()}
        guard let containgObserver = charactieristicsMapping.first(where: { CBUUID(string: $0.key.value) == characteristic.uuid }) else { return }
        containgObserver.value.forEach { observer in
            observer.triggerCounter += 1
            guard error == nil else { observer.action(.failure(error!)); return }
            callbackQueue.async { observer.action(.success(characteristic.value)) }
        }
    }
    
    // MARK: Writing values
    
    typealias writingValueCallback = (Result<Void, Error>) -> Void
    private var writingValueCallbacks: [CBCharacteristic: [writingValueCallback]] = [:]
    
    func sendMessage(data: Data, to device: BluetoothDevice, serviceID: String, characteristicID: String, completion: @escaping writingValueCallback) {
        let serviceUUID = CBUUID(string: serviceID)
        let characteristicUUID = CBUUID(string: characteristicID)
        guard let characteristic = getCharacteristic(serviceID: serviceUUID,
                                                     charID: characteristicUUID,
                                                     peripheral: device.peripheral) else {
            Log.error("Unable to get characteristic from \(device.peripheral)")
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
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        queue.async {
            Log.verbose("## Did write value for characteristic: \(characteristic), error: \(error)")
            self.writingValueCallbacks[characteristic]?.forEach { error == nil ? $0(.success(())) : $0(.failure(error!)) }
            self.writingValueCallbacks[characteristic] = nil
        }
        
    }
    
    // MARK: Central manager state
    
    
    private var deviceState: BluetoothDeviceState = .unknown
    
    func isBluetoothDenied() -> Bool {
        CBCentralManager.authorization != .allowedAlways || deviceState != .poweredOn
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            Log.info("central.state is .unknown")
            deviceState = .unknown
        case .resetting:
            Log.info("central.state is .resetting")
            deviceState = .resetting
        case .unsupported:
            Log.info("central.state is .unsupported")
            deviceState = .unsupported
        case .unauthorized:
            Log.info("central.state is .unauthorized")
            deviceState = .unauthorized
        case .poweredOff:
            Log.info("central.state is .poweredOff")
            deviceState = .poweredOff
        case .poweredOn:
            Log.info("central.state is .poweredOn")
            deviceState = .poweredOn
        @unknown default:
            fatalError()
        }
    }

}
