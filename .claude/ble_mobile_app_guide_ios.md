# Airbeam Mini V2 Firmware: iOS App Integration Guide

This document outlines how BLE communication operates in the new Airbeam Mini firmware and how the iOS app (`HabitatMap/AirCastingiOS`, default branch `develop`) should integrate it. It is the iOS counterpart of `ble_mobile_app_guide.md` (Android) and serves as a comprehensive reference for implementation.

The iOS app is Swift / SwiftUI, uses **CocoaPods**, **Resolver** for DI (`@Injected`), **CoreBluetooth** wrapped by `AirCasting/Utils/Bluetooth/BluetoothManager.swift`, and **closures/completion handlers** as the primary async primitive (no Combine / RxSwift in the BLE/sync layer). HTTP goes through `AirCasting/APICommunicator/APIClient.swift` over plain `URLSession`.

---

## If something is unclear, fetch and reference the firmware code:
https://github.com/HabitatMap/AirbeamMiniFirmware

## Reference Android implementation (separate repo):
https://github.com/HabitatMap/AircastingAndroid/tree/feat/ab-integration

That branch holds the full Android V2 integration — every commit hash referenced below lives there. See its `.claude/ble_mobile_app_guide.md` for the Android-side guide.

---

## 0. Key Differences from Old (V1) Firmware

| Aspect | Old Firmware (V1) | New Firmware (V2)                                                                                                                                                                           |
| ------ | ----------------- |---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **BLE Name** | `airbeammini` | `airbeammini` (same name)                                                                                                                                                                   |
| **Service UUID** | `0000ffdd-0000-1000-8000-00805f9b34fb` | `a0e1f000-0001-4b3c-8e9a-1f2d3c4b5a60`                                                                                                                                                      |
| **Protocol** | `0xFE/0xFF`-wrapped ASCII hex messages via single config characteristic | Binary little-endian opcodes via dedicated Command characteristic                                                                                                                           |
| **Characteristics** | Separate per-sensor (PM1, PM2.5, battery), config, SD card download | 5 purpose-based: Status, Command, Response, Measurement, Sync                                                                                                                               |
| **Auth** | UUID + auth token sent after connection | No auth. Only UUID sent as part of session config                                                                                                                                           |
| **Measurement format** | Semicolon-delimited ASCII string (parsed by `AirbeamMeasurementsRecordingServices`) | Binary: `[count_u8, timestamp_u32_LE, pm1_u16_LE, pm2_5_u16_LE]`                                                                                                                            |
| **Battery level** | Separate BLE characteristic (`0000ffe7`) | Embedded in Status notification byte                                                                                                                                                        |
| **Sync** | SD card CSV file download via dedicated characteristics | Binary records streamed via Sync characteristic (indicate)                                                                                                                                  |
| **Session config** | Multiple sequential `HexMessagesBuilder` writes (location, time, mode) | Single binary command `NewSessionConfig (0x13)`                                                                                                                                             |
| **Time sync** | Date string in `dd/MM/yy-HH:mm:ss` format | Unix epoch i64, sent at connection via `SetTime (0x15)` and then on mobile sessions also sent every hour                                                                                    |
| **Reconnection** | Reconfigure mobile session from scratch | `ContinueSession (0x10)` for mobile; Running state auto-streams. Fixed sessions auto-resume on the firmware side (BLE setup timeout + saved fixed session → WiFi reconnect, no app needed). |
| **Fixed-session offline buffering** | Existed but routed through SD card / app-driven sync                | Measurements persisted to littlefs when WiFi is down; replayed via WiFi POST when connectivity returns (firmware-only, no app involvement on current firmware `d15eff2`+).                  |

### Backward Compatibility

The V1 implementation must remain fully intact:
- `AirCasting/ABConnector/AirBeam3Configurator.swift` (also drives Mini V1)
- `AirCasting/ABConnector/HexMessagesBuilder.swift`
- `AirCasting/ABConnector/MeasurementsRecordingServices.swift` → `AirbeamMeasurementsRecordingServices`
- `AirCasting/ABConnector/SDCardAirBeamServices.swift` → `BluetoothSDCardAirBeamServices`
- `AirCasting/SDSync/Parsing/MiniSDCardMeasurementsParser.swift`
- `AirCasting/SDSync/Models/MiniSDSyncFileFactory.swift`
- `AirCasting/SDSync/SDSyncController.swift`

V2 is a parallel code path. **Do not touch** the V1 paths above except where a single shared seam (DI registration, scan filter, device type) must branch.

---

## 1. Device Detection (Old vs New Firmware)

Both old and new firmware devices advertise as `"airbeammini"`. The app must distinguish them by the **advertised service UUID** in the BLE scan result.

- **Old firmware** advertises service UUID: `0000ffdd-0000-1000-8000-00805f9b34fb`
- **New firmware** advertises service UUID: `a0e1f000-0001-4b3c-8e9a-1f2d3c4b5a60`

### iOS Implementation

CoreBluetooth scan results carry advertised service UUIDs in `advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]`. Inspect this at scan time inside `AirCasting/Utils/Bluetooth/BluetoothManager.swift` (the `centralManager(_:didDiscover:advertisementData:rssi:)` callback) and stamp a firmware-version flag onto the `BluetoothDevice` instance:

- Contains `a0e1f000-0001-...` → V2 firmware → route to `AirBeamMiniV2Configurator`
- Contains `0000ffdd-...` (or no match) → V1 firmware → route to existing `AirBeam3Configurator`

Add a `FirmwareVersion` enum (e.g. `.v1 / .v2`) and store it on `BluetoothDevice` (both the protocol and the concrete `CBPeripheral`-backed implementation in `AirCasting/Utils/Bluetooth/BluetoothDevice.swift`). The `airbeamType` extension already differentiates `.airBeamMini` — add the firmware-version probe alongside it.

### Existing files to modify
- **`AirCasting/Utils/Bluetooth/BluetoothDevice.swift`** — add `firmwareVersion: FirmwareVersion` (default `.v1`)
- **`AirCasting/Utils/Bluetooth/BluetoothManager.swift`** — read advertised service UUIDs, set `firmwareVersion` on the discovered device
- **`AirCasting/SearchAndFollow/AirBeamMeasurements/AirBeamDeviceType.swift`** — keep `.airBeamMini`, branch internally on `firmwareVersion` rather than introducing a new device type
- **`AirCasting/AppDelegate+Injection.swift`** — replace the single `AirBeamConfigurator` registration with a factory closure that returns either `AirBeam3Configurator` or `AirBeamMiniV2Configurator` based on `BluetoothDevice.firmwareVersion`
- **`AirCasting/ABConnector/AirBeamConnectionController.swift`** (`DefaultAirBeamConnectionController`) — route V2 devices through the V2 configurator; the connection controller does not need to know the protocol details if the configurator hides them behind the `AirBeamConfigurator` protocol

> Stamp the `FirmwareVersion.v2` on the `BluetoothDevice` only after a successful V2 GATT discovery (not just after scan). The Android codebase learned this lesson in commit `bf0325243` — scan-time stamping is unreliable when the user reconnects from a stored device list. Persist it on the `Device` Core Data entity if needed.

---

## 2. BLE GATT Infrastructure (V2)

The device acts as a peripheral BLE GATT Server.

**Service UUID:** `a0e1f000-0001-4b3c-8e9a-1f2d3c4b5a60`

**Characteristics:**

| Name            | UUID | Permissions | Description |
|-----------------| ---- | ----------- | ----------- |
| **Status**      | `a0e1f000-0002-4b3c-8e9a-1f2d3c4b5a60` | Notify | Device sends its state (Idle, Running, HasSavedSession) + battery level. |
| **Command**     | `a0e1f000-0003-4b3c-8e9a-1f2d3c4b5a60` | Write | App writes binary `AppCommand`s (little-endian byte streams). |
| **Response**    | `a0e1f000-0004-4b3c-8e9a-1f2d3c4b5a60` | Notify | Device sends replies: Ack, Nack, Ready, SensorInfo, SyncInfo. |
| **Measurement** | `a0e1f000-0005-4b3c-8e9a-1f2d3c4b5a60` | Indicate | Live measurement stream during active session. |
| **Active Sync** | `a0e1f000-0006-4b3c-8e9a-1f2d3c4b5a60` | Indicate | Device streams historical (stored) measurements automatically after reconnection. Not manually triggered. |

### Connection Flow (No Auth)

1. Connect to peripheral via `CBCentralManager.connect(_:options:)`
2. Discover the V2 service in `peripheral(_:didDiscoverServices:)` and verify it equals `a0e1f000-0001-...`
3. Subscribe to Status, Response, Measurement, Sync via `peripheral.setNotifyValue(true, for:)` for all four
4. Wait ~300ms for the device to settle before any other action
5. Device automatically sends Status notification with current state + battery level
6. App reads Status and decides next action (no auth handshake needed)

> CoreBluetooth subscribes both Notify and Indicate characteristics through the same `setNotifyValue(true, for:)` call — the framework picks the right CCCD bit based on the characteristic's `properties`. No separate writeDescriptor call is needed.

### MTU

iOS does not expose `requestMtu()`. The negotiated ATT MTU is governed by the system and is read from `CBPeripheral.maximumWriteValueLength(for: .withResponse)` (and `.withoutResponse`). Sync chunks can be up to **244 bytes**, which fits within the iOS default ATT MTU of 185 + 17 bytes of overhead on most modern iPhones; verify on the lowest-supported device. If chunks come in truncated, this is the place to look. Android explicitly requests MTU 247 in commit `1c29a7e16` — iOS has no equivalent; rely on Apple's connection-time negotiation.

---

## 3. Status Notifications (`Status` Characteristic)

On connection (after ~300ms delay), the device sends a state notification. The app uses this to understand the device context.

- `0x00` **Idle**: Payload = `[0x00, battery_level_u8]`. No ongoing session.
- `0x01` **HasSavedSession**: Payload = `[0x01, battery_level_u8, session_uuid_16B_LE, has_measurements_u8_bool]`. Active session stored on device (device was turned off and on).
- `0x02` **Running**: Payload = `[0x02, battery_level_u8, session_uuid_16B_LE]`. Session actively running.

If the first Status notification is missed (e.g. subscription completed too late), explicitly read the Status characteristic via `peripheral.readValue(for: statusCharacteristic)`. Android learned this lesson in commit `9ec55ffb2`.

### Battery Level

Battery level byte is a **signed `Int8`** in firmware, transmitted as `UInt8` via two's complement:
- **Positive value** → charging (e.g. `54` = 54% and charging)
- **Negative value** → discharging (e.g. `-54` → transmitted as `202` raw, means 54% discharging)

Swift decoding:
```swift
let raw = data[1]                         // UInt8
let signed = Int8(bitPattern: raw)        // -128…127
let percentage = abs(Int(signed))         // 0…100
let isCharging = signed >= 0
```

It arrives:
- In every Status notification (all states)
- Updated with each live measurement sent (Status is re-notified alongside Measurement indications)

This replaces the old separate battery characteristic (`0000ffe7`).

### App Behavior per Status

| Status | Mobile Session | Fixed Session |
| ------ | -------------- | ------------- |
| **Idle** | Start new session via `NewSessionConfig` | Start new session via `NewSessionConfig` |
| **HasSavedSession** | **Reconnection path:** send `ContinueSession (0x10)` — device transitions to Running and streams both sync + live data. **New-session path:** send `DiscardSession (0x11)` first to wipe stored data (or prompt the user via the unsynced-measurements dialog), then `NewSessionConfig`. Choice is the app's, not the device's. | N/A (fixed sessions don't reconnect this way; firmware auto-resumes via WiFi — see §6b) |
| **Running** | Sync + live data flow automatically (interleaved) on the BLE Sync + Measurement characteristics. No command needed. | Measurements flow **server-side over WiFi**, not over BLE. The app does NOT need to subscribe to BLE Measurement / Sync to receive them — they appear on the AirCasting backend. BLE is only used for status / stop / reconfigure. |

**Note:** On `HasSavedSession` the app picks `ContinueSession` vs `DiscardSession` based on user intent (resuming a session that was force-quit vs starting a new one). For `Running` (mobile, phone went out of range), Sync + Live both stream automatically on BLE reconnection — no command needed.

---

## 4. Responses (`Response` Characteristic)

All replies to app commands arrive as notification bytes on the Response characteristic.

- `0x20` **Ack**: Command understood. Wait for further replies (like `Ready`) if applicable.
- `0x21` **Nack**: Command rejected. Next byte = Error Code:
  - `0x01`: NoSession
  - `0x02`: InvalidConfig (generic config failure; for fixed sessions also fires if the **first** measurement POST fails after the session is freshly configured — firmware signals this and then stops, expecting the app to reconfigure)
  - `0x03`: StorageHasMeasurements
  - `0x04`: ClearStorageFailed / SyncStorageFailed
  - `0x05`: **InvalidWifiCredentials** — sent when `NewSessionConfig` WiFi connect fails because the credentials themselves are wrong (distinct from `0x02`). App should prompt user to re-enter SSID/password.
- `0x22` **Ready**: Procedure complete (e.g., WiFi connected, sync finished, storage cleared). For a running fixed session, firmware also emits `Ready` after **every successful measurement POST** while BLE is connected — i.e. it doubles as a per-measurement heartbeat. The app must treat repeated `Ready` as idempotent: the first one completes the configure flow / kicks off setup work; subsequent ones are heartbeat-only and must not re-trigger setup.
- `0x23` **SensorInfo**: Response to `GetSensors`. Bytes after `0x23` = ASCII string `"PM1,μg/m3;PM2.5,μg/m3"`.
- `0x24` **SyncInfo**: Response to `StartSync`. Bytes after `0x24` = `32B_WiFi_SSID_string` + `64B_WiFi_Password_string` (null-padded).

### iOS dispatch pattern

Maintain a `pendingCommand` enum / completion-handler dictionary keyed by the opcode you wrote. When a Response notification arrives, decode the first byte, dispatch to the registered handler, and clear it once `Ready` (terminal) arrives. For commands with an Ack-then-Ready two-stage protocol (`NewSessionConfig`, `StartSync`), do not invoke the user-visible completion until `Ready` lands. Android commit `b266c57ab` corrected this — only `NewSessionConfig` / `ContinueSession` `Ready` should be treated as session-start; other `Ready`s (heartbeat, sync-done) must route to their own handlers.

---

## 5. `AppCommand` Scenarios (`Command` Characteristic)

All numerical values encoded as **Little Endian**. Use `withUnsafeBytes` / `Data` extensions; do NOT rely on `CFSwapInt32HostToLittle` in code that runs on Apple Silicon — the host is already little-endian, but writing the explicit byte order keeps intent clear.

### A. `ContinueSession` (OpCode `0x10`)

**Payload:** Single byte `0x10`.
**Context:** Resume a saved session after device was turned off and on. **Only needed for mobile sessions.**

Per firmware design, on `Ack (0x20)` the device transitions to Running and **automatically streams both live measurements and the stored (unsynced) ones** — no separate sync command is needed. The presence of stored measurements is NOT a reason to reject `ContinueSession`.

- **Has Stored Measurements:** `Ack (0x20)`. Live + sync data flow on Measurement / Sync characteristics automatically.
- **No Stored Measurements:** `Ack (0x20)`. Resumes running state, live data flows.
- **No Saved Session:** `Nack (0x01 NoSession)`.

> **Android caveat:** `AirBeamMiniV2Configurator.kt:755-778` contains a `Nack(0x03 StorageHasMeasurements) → StartSync → retry ContinueSession` path (commit `db3cebf24`). This is **incorrect** — the firmware does not Nack `ContinueSession` for stored measurements; the path was added on a wrong assumption and is unreachable. Do **NOT** port it to iOS. If `Nack(0x03)` ever arrives on `ContinueSession`, treat it as an anomaly (log + surface to user); do not auto-send `StartSync`.

### B. `DiscardSession` (OpCode `0x11`)

**Payload:** Single byte `0x11`.
**Context:** Terminate session, wipe locally stored measurements. Also stops a running session.

- `Ack (0x20)`, then attempts wipe.
  - Success: `Ready (0x22)`.
  - Failure: `Nack (0x04 ClearStorageFailed)`.

**iOS wiring:** When the user stops a session (mobile or fixed), the V2 configurator must `writeValue(_:for:type:)` the `0x11` byte and then **wait for the `Ready (0x22)` response** before disconnecting (`cancelPeripheralConnection`). Use `.withResponse` write type and chain into the Response notification handler — disconnecting on the BLE write ack alone leaves the firmware in `Running` state. Android learned this in commits `a8f4a8c15` and `1b89ba35d`. Mirror in iOS by adding a `discardSession(completion:)` to the `AirBeamConfigurator` protocol with a default no-op (V1 does not need it) and a real implementation on `AirBeamMiniV2Configurator`.

### C. `StartSync` (OpCode `0x12`) — NOT YET IMPLEMENTED ON FIRMWARE

**Payload:** Single byte `0x12`.
**Context:** Will be the **full file sync** primitive — used for the SD-sync replacement and the "sync old measurements before starting a new session?" dialog. **Active sync** (the auto-stream on the Sync characteristic during mobile reconnection) is a separate, already-shipped flow that does NOT use this opcode.

When firmware ships this:
- `Ack (0x20)`, then `SyncInfo (0x24)` with WiFi SSID + password.
- Historical records stream on Sync characteristic as chunked indications.
  - Success: `Ready (0x22)`.
  - Failure: `Nack (0x04)`.

**iOS Phase note:** Do **NOT** port the SD-sync replacement to iOS yet. Skip the StartSync wiring entirely until firmware support lands. The existing iOS `SDSyncController` / `BluetoothSDCardAirBeamServices` / `MiniSDCardMeasurementsParser` paths stay untouched and unused for V2 in the meantime.

### D. `NewSessionConfig` (OpCode `0x13`)

**Payload (Mobile):** `0x13` + `16B_UUID` + `2B_interval_seconds(u16)` + `0x01`
Mobile sessions do **not** include `session_token` — the field is absent from the payload entirely.

**Payload (Fixed):** `0x13` + `16B_UUID` + `2B_interval_seconds(u16)` + `0x00` + `1B_pm1_index` + `1B_pm2_5_index` + `16B_session_token` + `32B_WiFi_SSID` + `64B_WiFi_Password`
Total: 134 bytes. Strings are null-byte padded to their container lengths. **Byte 19 is the mode byte (0x00=FIXED, 0x01=MOBILE)** — the firmware reads this to distinguish session types, so the order matters. The `session_token` (16 bytes) comes AFTER the indices, not immediately after the UUID.

**Interval per session type:**
- Mobile: `interval_seconds = 1` (1 measurement per second)
- Fixed: `interval_seconds = 60` (1 measurement per minute)

### UUID Byte Encoding (Little-Endian)

All UUIDs in V2 binary payloads use **mixed-endian (LE)** encoding, matching the firmware's `Uuid::from_slice_le()`:
- The first three groups are byte-reversed: time_low (4B), time_mid (2B), time_hi_and_version (2B)
- The last 8 bytes (clock_seq + node) remain in standard order

Example: UUID `"a4a3a2a1-b2b1-c2c1-d1d2-d3d4d5d6d7d8"` encodes as bytes `[a1,a2,a3,a4, b1,b2, c1,c2, d1,d2,d3,d4,d5,d6,d7,d8]`.

Swift helper:
```swift
extension UUID {
    func toLEBytes() -> Data {
        var bytes = Data(count: 16)
        let u = self.uuid // tuple of 16 UInt8
        let std: [UInt8] = [u.0,u.1,u.2,u.3,u.4,u.5,u.6,u.7,u.8,u.9,u.10,u.11,u.12,u.13,u.14,u.15]
        bytes[0..<4]   = Data(std[0..<4].reversed())
        bytes[4..<6]   = Data(std[4..<6].reversed())
        bytes[6..<8]   = Data(std[6..<8].reversed())
        bytes[8..<16]  = Data(std[8..<16])
        return bytes
    }
    static func fromLEBytes(_ data: Data) -> UUID? { /* inverse of above */ }
}
```

**Context:** Start recording a new session.

- **Mobile:** `Ack (0x20)` → `Ready (0x22)` → starts tracking.
- **Fixed:**
  - `Ack (0x20)`.
  - Firmware attempts WiFi connection with provided credentials.
  - Success: `Ready (0x22)` — and then another `Ready` after each subsequent measurement POST while BLE is connected (per-measurement heartbeat).
  - Failure: `Nack (0x02 InvalidConfig)` (generic / first-measurement POST failure) or `Nack (0x05 InvalidWifiCredentials)`.

### E. `GetSensors` (OpCode `0x14`)

**Payload:** Single byte `0x14`.
**Context:** Query which sensor metrics the hardware supports.

- Response: `0x23` + ASCII bytes `"PM1,μg/m3;PM2.5,μg/m3"`.

### F. `SetTime` (OpCode `0x15`)

**Payload:** `0x15` + `8B_unix_epoch_seconds(i64_LE)`.
**Context:** Synchronize firmware's internal RTC.

- Updates internal system time. **No Ack emitted.**
- **Must be sent on connection and repeated every hour for mobile sessions only.**

iOS scheduling: use a `Timer.scheduledTimer(withTimeInterval: 3600, repeats: true)` retained on the V2 configurator, invalidated on disconnect. Avoid `DispatchSourceTimer` unless you need precise scheduling — the periodicity here is loose. **Do NOT schedule the hourly timer for fixed sessions** (the firmware gets time from the WiFi POST `X-Server-Time` header).

---

## 6. Measurement Data Format (Binary)

### Live Measurements (`Measurement` Characteristic — Indicate)

Single measurement, 9 bytes:
```
[count_u8=1, timestamp_u32_LE, pm1_u16_LE, pm2_5_u16_LE]
```

- `count`: Always `1` for live measurements.
- `timestamp`: Unix epoch seconds, `u32` little-endian.
- `pm1`: PM1.0 value in μg/m³, `u16` little-endian.
- `pm2_5`: PM2.5 value in μg/m³, `u16` little-endian.

After each live measurement indication, the device also re-notifies the Status characteristic with `Running` state (updating battery level).

Swift decoder:
```swift
struct V2LiveMeasurement {
    let timestamp: Date
    let pm1: UInt16
    let pm25: UInt16
}
extension Data {
    func parseV2Live() -> V2LiveMeasurement? {
        guard count >= 9, self[0] == 1 else { return nil }
        let ts  = withUnsafeBytes { $0.load(fromByteOffset: 1, as: UInt32.self).littleEndian }
        let p1  = withUnsafeBytes { $0.load(fromByteOffset: 5, as: UInt16.self).littleEndian }
        let p25 = withUnsafeBytes { $0.load(fromByteOffset: 7, as: UInt16.self).littleEndian }
        return V2LiveMeasurement(timestamp: Date(timeIntervalSince1970: TimeInterval(ts)),
                                 pm1: p1, pm25: p25)
    }
}
```

### Historical/Sync Measurements (`Sync` Characteristic — Indicate)

Batched records, up to 244 bytes:
```
[count_u8, padding_2B, record_0(8B), record_1(8B), ...]
```

Each record is 8 bytes:
```
[timestamp_u32_LE, pm1_u16_LE, pm2_5_u16_LE]
```

- `count`: Number of records in this chunk.
- Records start at byte offset 3.

**This replaces the old SD card CSV file download entirely.** `BluetoothSDCardAirBeamServices`, `SDSyncController.syncFromAirbeam(...)`, `MiniSDCardMeasurementsParser`, and `MiniSDSyncFileFactory` are **not used** for V2.

### Mapping to the iOS measurement persistence layer

The V2 binary format does NOT include sensor metadata (package name, thresholds, etc.) like the old ASCII format. The V2 configurator must construct the equivalent of `ABMeasurementStream` using:
- Sensor info from `GetSensors` response: `"PM1,μg/m3;PM2.5,μg/m3"`
- Hardcoded thresholds matching the AirBeam Mini sensor profile (lift them from `AirBeam3Configurator` / the V1 stream definitions to keep parity)
- Device ID from the connected `BluetoothDevice`

Persist via `MeasurementsSavingService` directly (do NOT route V2 live measurements through the EventBus-style `NewMeasurementEvent` analog if iOS has one — V2 owns its own DB writes). For UI refresh, post a notification (e.g., `NotificationCenter`) so `SessionDetailsViewController` and the live-streaming graph update on each measurement. Android learned this in commit `3d69a19c3`.

The old `AirbeamMeasurementsRecordingServices` (semicolon-string parser) is **not reusable** for V2 — a new binary parser is needed.

---

## 6a. Fixed Session — WiFi-Drop Storage & Replay

When a fixed session is running and WiFi drops (or fails to connect), the
firmware does NOT lose measurements. Storage replay is a **firmware-side
concern handled over WiFi** — the app does not participate.

1. `send_measurement` (fixed path) POSTs to
   `/api/v3/fixed_sessions/{uuid}/measurements` via
   `wifi_manager.send_measurements(...)`.
2. If WiFi is not connected, the record is persisted to littlefs storage
   (`src/main.rs:171-175`).
3. Every main-loop tick (100 ms), if `storage.has_measurements() &&
   wifi_manager.is_connected()`, firmware replays stored records through
   the WiFi POST endpoint via `sync_from_storage` (`src/main.rs:198-204`,
   closure routes FIXED → WiFi, MOBILE → BLE).
4. The WiFi POST response includes an `X-Server-Time` header parsed into
   `LoopEvent::TimeUpdate`, keeping the device clock server-authoritative.
   `SetTime` BLE hourly scheduling remains unused for fixed sessions.
5. `connected()` predicate in the main loop is WiFi for FIXED, BLE for
   MOBILE — so sync loop only fires on the correct transport.

**First-measurement failure signalling (commit `25f94a1`):** On a freshly
started fixed session, if the first measurement send fails AND BLE is
still connected, firmware emits `Nack(0x02 InvalidConfig)` and stops the
loop — a hint to the app that WiFi creds/connectivity are bad.
Suppressed on resumed sessions (see §6b).

---

## 6b. Fixed Session — Firmware-Side Resume (No App Required)

Commit `25f94a1` added autonomous resume for fixed sessions:

- On BLE setup timeout, if a saved FIXED session exists on the device,
  firmware auto-reconnects WiFi and returns `SetupResult::Continue`. The
  session keeps running **without the app**.
- First-measurement WiFi failure signalling is suppressed in this
  resumed path (avoid re-prompting creds on every power-cycle).

### iOS Implication

On BLE reconnect to a fixed-session device:
- Status notification may be `Running (0x02)` with a session UUID the
  app already knows — treat as normal continuation.
- Do NOT assume "no session running" just because the app wasn't
  involved in the latest setup. Always trust Status.
- No `ContinueSession (0x10)` is needed for fixed sessions (still mobile-only).

---

## 7. Fixed Session Flow (Backend Integration)

### Step-by-step

1. App sends `GetSensors (0x14)` → receives `"PM1,μg/m3;PM2.5,μg/m3"`
2. App calls backend `POST /api/v3/fixed_sessions` (new endpoint — V1 fixed sessions used a different path; add a new method on `AirCasting/APICommunicator/APIClient.swift` or a dedicated `V2FixedSessionAPIService`):

**Request:**
```json
{
  "uuid": "<session-uuid>",
  "title": "...",
  "latitude": 40.7128,
  "longitude": -74.006,
  "contribute": true,
  "is_indoor": false,
  "airbeam": {
    "mac_address": "AA:BB:CC:DD:EE:FF",
    "model": "AirBeamMini",
    "name": "..."
  },
  "streams": [
    { "sensor_name": "AirBeamMini-PM1", "unit_symbol": "µg/m³" },
    { "sensor_name": "AirBeamMini-PM2.5", "unit_symbol": "µg/m³" }
  ]
}
```

**Response:**
```json
{
  "location": "http://aircasting.org/s/ab12c",
  "session_token": "a3f2c1d4e5b6a7f8c9d0e1f2a3b4c5d6",
  "streams": [
    { "sensor_name": "AirBeam-PM2.5", "sensor_type_id": 2 }
  ]
}
```

3. `streams[].sensor_type_id` values become `pm1_index` and `pm2_5_index` in the `NewSessionConfig` payload.
4. `session_token` is a 16-byte integer stored by the backend and returned as a 32-char hex string. Decode it to 16 raw bytes, then **reverse the byte order to little-endian** before including in the BLE payload — firmware reads it via `u128::from_le_bytes(...)`. The hex string is big-endian (MSB first), so `Data(tokenBytes.reversed())` is required. Android commit `97bbe0f38` had to fix this ordering after initial implementation.
5. App sends `NewSessionConfig (0x13)` with all the above data + WiFi credentials.

> Always use **HTTPS** in `baseUrl()` and **port 443** by default. The Android app fixed a `POST → GET` redirect in commit `caf2dc3b0` caused by `http://` triggering a 301 from the load balancer. Same applies on iOS — verify `APIClient` URL construction.

> Use a typed `Decodable` model for the V3 endpoint, not raw `Data` — Android commit `448cff1a5` reverted to typed deserialization after a debug detour.

> If the configure call fails, **keep the local fixed-session row in Core Data** so the user can retry without losing their input. Android commit `dd05d7989` did this.

> On configure success, **disconnect BLE** — the device runs the fixed session over WiFi from this point on. Reconnect only when the user opens session details or stops the session. Android commit `3708d75e4`.

---

## 8. `SetTime` Periodic Scheduling

`SetTime (0x15)` must be sent:
1. Immediately after connection (once Status is received)
2. Every hour while connected — **only for mobile sessions**. Fixed sessions get time from the backend server: the WiFi POST to `/api/v3/fixed_sessions/{uuid}/measurements` returns an `X-Server-Time` header that firmware parses into an internal `TimeUpdate` event (guarded by a ≥60s delta to avoid clock thrash). App must NOT schedule hourly `SetTime` for fixed sessions.

Use a `Timer` on the configurator instance (1-hour period). The command does not produce an Ack response — fire-and-forget write with `.withoutResponse`.

---

## 9. Mobile Session Reconnection (Phase 3)

When the app reconnects to the device during an active mobile session, two scenarios apply:

### Scenario A: Device was Running (phone went out of range)

The device continued recording while disconnected. On BLE reconnect:
1. Status notification = `Running (0x02)`
2. **No command needed** — device automatically streams:
   - Stored measurements on **Sync characteristic** (batched indications)
   - Live measurements on **Measurement characteristic**
   - Both can be interleaved
3. App parses Sync indications and saves each chunk to Core Data with original timestamps
4. When all stored data is streamed, Status re-notifies as `Running` with `has_measurements=false`

### Scenario B: Device was power-cycled (HasSavedSession)

The device was turned off and back on. On BLE reconnect:
1. Status notification = `HasSavedSession (0x01)` with `has_measurements` flag
2. App sends `ContinueSession (0x10)` — device transitions to Running immediately
3. From here, same as Scenario A: sync + live data flow interleaved
4. App parses and saves sync chunks to DB

### Sync Data Format (Sync Characteristic — Indicate)

Batched records, up to 244 bytes:
```
[count_u8, padding_2B, record_0(8B), record_1(8B), ...]
```
Each 8-byte record: `[timestamp_u32_LE, pm1_u16_LE, pm2_5_u16_LE]`

Each chunk is saved to the DB immediately (not accumulated) since there can be many stored measurements.

### Key Implementation Detail

`StartSync (0x12)` is **NOT** used for mobile reconnection sync — and it is **not yet implemented on the firmware side at all**. The mobile-reconnection sync (active sync) is firmware-driven and automatic on the Sync characteristic; no app command triggers it. `StartSync` will eventually drive the SD-sync replacement and the pre-new-session "sync old measurements?" flow, but until firmware ships it, do not wire it into iOS.

Android also has a `Nack(0x03 StorageHasMeasurements) → StartSync → retry ContinueSession` path at `AirBeamMiniV2Configurator.kt:755-778` (commit `db3cebf24`). **This is incorrect** — the firmware does not Nack `ContinueSession` when stored measurements exist; on `Ack` the device streams both live and stored data automatically. Do not port that branch to iOS.

### Session UUID Validation for Sync Data

When sync measurements arrive on the Sync characteristic, **always verify the device's session UUID** (from the last Status notification, stored as `savedSessionUuid` on the V2 configurator) matches the current app session UUID before saving. If they don't match, the sync data is from an older session that the device still had in storage — **discard it**. Android commit `18e16b89f`.

The device UUID arrives in LE-encoded form and must be decoded with `UUID.fromLEBytes(...)` (see §5 helper) before comparing to the Core Data session UUID.

### Live Measurements — Direct DB Save + UI Notification

V2 saves live measurements **directly** through `MeasurementsSavingService`, using the device timestamp from the binary packet and the full device ID from the V2 configurator. Skip whatever EventBus-style observer flow the V1 path uses for mobile sessions — V2 owns its own writes; UI notification is a separate concern (post a `NotificationCenter` event so the live graph and active controllers refresh). Android commit `3d69a19c3` and `18e16b89f` for context.

### Sync Confirmation Dialogs

Before starting a new session OR finishing a session on a V2 device that has unsynced measurements stored, show a confirmation dialog ("You have unsynced measurements — sync now?"). The "sync now" branch will eventually call `StartSync (0x12)` once firmware supports it; for now the dialog can offer **Discard** (sends `DiscardSession (0x11)`) or **Cancel**. Android commits `b7e2c2ca2` and `3086e1dc0` added the dialogs. iOS should mirror in:
- `CreateSessionViews/...ConnectingABViewModel.swift` (start path)
- `BluetoothSession/...RecordingController` (finish path)
- And the disconnected-view equivalent

### Discard before new session

When the user starts a new V2 mobile session and the device is in `HasSavedSession`, send `DiscardSession (0x11)` first to wipe the stored session, wait for `Ready`, then send `NewSessionConfig`. Android commit `ac5925900`.

---

## 10. Error Surfacing

V2 introduces several distinct failure modes that the app must surface clearly:

- `Nack(0x02 InvalidConfig)` — show a generic "Could not configure session" dialog
- `Nack(0x05 InvalidWifiCredentials)` — show a "WiFi credentials wrong, please re-enter" dialog and route the user back to the WiFi entry screen
- `Nack(0x03 StorageHasMeasurements)` on `ContinueSession` — should not occur per firmware design (`ContinueSession` Acks regardless of stored measurements and streams live + stored automatically). If it does occur, treat as anomaly: log and surface a generic error. Do NOT auto-send `StartSync` (that's the dead/wrong Android path at `AirBeamMiniV2Configurator.kt:755-778`).
- `Nack(0x01 NoSession)` — silent; treat as Idle and proceed
- `Nack(0x04 ClearStorageFailed)` — log; the next connection will retry

Use a single dialog component (mirror Android `d6749096e` which switched from Toast to dialog) and **lock it down** so the user can't accidentally bypass on fixed-session configure failure (Android commit `3708d75e4`). On iOS this is a `UIAlertController` with a single OK action and `isModalInPresentation = true` on the wrapping VC, or an SwiftUI `.alert` bound to a non-dismissable state.

Block the "Start Recording" button on fixed-session configure outcome — don't let the user start two sessions in flight (Android commit `73cf51072`).

---

## 11. Reference: Files to Create / Modify on iOS

### New files (V2-only)
- `AirCasting/ABConnector/V2/AirBeamMiniV2Configurator.swift` — implements `AirBeamConfigurator`; owns Status/Command/Response/Measurement/Sync subscriptions, command writes, response dispatch, `SetTime` timer, `discardSession`
- `AirCasting/ABConnector/V2/V2BinaryProtocol.swift` — opcodes, payload builders, response parsers, UUID LE helpers, battery decoder
- `AirCasting/ABConnector/V2/V2MeasurementParser.swift` — live + sync chunk parsers
- `AirCasting/ABConnector/V2/V2ResponseDispatcher.swift` — registers per-opcode completion handlers; routes Ack / Nack / Ready / SensorInfo / SyncInfo
- `AirCasting/SDSync/V2/V2FixedSessionAPIService.swift` — `POST /api/v3/fixed_sessions` typed Decodable round-trip
- `AirCasting/CreateSessionViews/V2SyncConfirmationView.swift` — pre-start / pre-finish unsynced-measurements dialog

### Modified files
- `AirCasting/Utils/Bluetooth/BluetoothManager.swift` — read advertised service UUIDs at scan time, set `firmwareVersion` on `BluetoothDevice`
- `AirCasting/Utils/Bluetooth/BluetoothDevice.swift` — add `firmwareVersion` property + `FirmwareVersion` enum
- `AirCasting/AppDelegate+Injection.swift` — register `AirBeamConfigurator` factory branching on `firmwareVersion`
- `AirCasting/ABConnector/AirBeamConnectionController.swift` — pass `firmwareVersion` through; stamp it on the device after successful V2 GATT discovery
- `AirCasting/ABConnector/AirBeamConfigurator` protocol — add `func discardSession(completion: @escaping (Result<Void, Error>) -> Void)` with default no-op
- `AirCasting/BluetoothSession/BluetoothSessionRecordingController.swift` (+ `MobileAirBeamSessionRecordingController`) — call `discardSession` on stop for V2; skip the V1 measurement-observer pipeline for V2
- `AirCasting/BluetoothSession/ReconnectionController.swift` — handle V2 `HasSavedSession` → `ContinueSession`; defer until Status arrives (Android commit `2ae1e99fa`)
- `AirCasting/APICommunicator/APIClient.swift` — ensure `https://` + port 443 default
- `AirCasting/Models/SessionContext.swift` / `AirBeamFixedWifiSessionCreator.swift` — branch on V2: call `V2FixedSessionAPIService` and pass response into `AirBeamMiniV2Configurator.startFixedSession(...)`

### Untouched (V1)
- `AirBeam3Configurator.swift`, `HexMessagesBuilder.swift`, `MeasurementsRecordingServices.swift`, `SDCardAirBeamServices.swift`, `MiniSDCardMeasurementsParser.swift`, `MiniSDSyncFileFactory.swift`, `SDSyncController.swift`, `UploadFixedSessionAPIService.swift` — all stay as-is.

### Deferred (do not port until firmware ships `StartSync (0x12)`)
- The full-file SD-sync replacement (the `StartSync (0x12)` flow described in §5.C). The active sync on the Sync characteristic during mobile reconnection is a separate, already-shipped flow and IS in scope for Phase 3.
- iOS keeps the existing V1 SD-sync stack (`SDSyncController`, `BluetoothSDCardAirBeamServices`, `MiniSDCardMeasurementsParser`, `MiniSDSyncFileFactory`) untouched and unused for V2 in the meantime.

---

## 12. Cross-reference: Android commits for each behavior

When in doubt, read the Android implementation in https://github.com/HabitatMap/AircastingAndroid/tree/feat/ab-integration. Key commits since base `9c91d24856e0be6bd5794a0ef2b74a3cce5ceed5`:

| Behavior | Android commit |
|---|---|
| Phase 1 connection infra | `f63f3abf3` |
| Phase 2 mobile session config | `cd666ed21` |
| Phase 3 mobile reconnection sync | `84050172a` |
| Fixed session implementation | `5b48f6159` |
| MTU 247 request (live + sync) | `1c29a7e16` |
| `DiscardSession` on stop + write-completion wait | `d9a29f896`, `a862f1583`, `a8f4a8c15`, `1b89ba35d` |
| `Nack(0x05)` WiFi creds + gate hourly SetTime to mobile | `8198f4445` |
| Per-measurement `Ready` heartbeat | `913e1d58d` |
| Block Start Recording on fixed configure outcome | `73cf51072` |
| Disconnect BLE on fixed V2 success + lock down dialog | `3708d75e4` |
| Keep local row on configure failure | `dd05d7989` |
| Toast → Dialog | `d6749096e` |
| Live-graph update during V2 recording | `3d69a19c3` |
| Single error dialog on fixed-config failure | `bd92f041b` |
| Treat only NewSessionConfig/ContinueSession Ready as session-start | `b266c57ab` |
| HTTPS / port 443 | `caf2dc3b0`, `39c0a59b0` |
| V3 endpoint typed deserialization | `448cff1a5` |
| Session_token little-endian | `97bbe0f38` |
| Fixed interval 60s | `7659eeb01` |
| Parse fixed end_time as UTC | `b21931159` |
| Sync UUID validation + direct DB save | `18e16b89f`, `489902d59` |
| Discard before new session | `ac5925900` |
| `ContinueSession` Nack(0x03) auto-recover via StartSync | `db3cebf24` |
| MTU + larger sync chunks | `1c29a7e16` |
| Stamp `FirmwareVersion.V2` on successful V2 connection | `bf0325243` |
| Read Status to recover missed notification | `9ec55ffb2` |
| Battery as signed i8 | `ab84c44f6` |
| Defer reconnect until Status arrives | `2ae1e99fa` |
| Surface V2 Nack errors + handle Nack(0x03) | `884cbd24b` |
| Sync dialogs (start + finish + disconnected) | `b7e2c2ca2`, `3086e1dc0` |
| Off-by-one indexOfPresenter crash on first measurement | `d35b566e6` |
