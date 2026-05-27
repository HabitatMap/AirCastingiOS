# Airbeam Mini V2 Firmware: iOS App Integration Guide

This document outlines how BLE communication operates in the new Airbeam Mini firmware and how the iOS app (`HabitatMap/AirCastingiOS`, default branch `develop`) should integrate it. It is the iOS counterpart of `ble_mobile_app_guide.md` (Android) and serves as a comprehensive reference for implementation.

The iOS app is Swift / SwiftUI, uses **CocoaPods**, **Resolver** for DI (`@Injected`), **CoreBluetooth** wrapped by `AirCasting/Utils/Bluetooth/BluetoothManager.swift`, and **closures/completion handlers** as the primary async primitive (no Combine / RxSwift in the BLE/sync layer). HTTP goes through `AirCasting/APICommunicator/APIClient.swift` over plain `URLSession`.

---

## If something is unclear, fetch and reference the firmware code:
https://github.com/HabitatMap/AirbeamMiniFirmware

The current shipped BLE manual sync (`StartBleSync 0x16`) lives on `main` — firmware commits `e1a03b9415a8a4e70ee24acb824c1361f526d53c` and `c4dd9e62d5df599601d4edf57e5b8f5386440564`. The legacy WiFi-SoftAP manual file-sync flow (`StartWiFiSync 0x12`) is dormant in the same tree.

## Reference Android implementation (separate repo):
https://github.com/HabitatMap/AircastingAndroid/tree/dev

The `dev` branch holds the full Android V2 integration — every commit hash referenced below is fetchable from it (verified May 2026). The earlier `feat/ab-integration` branch also contains them. See its `.claude/ble_mobile_app_guide.md` for the Android-side guide.

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
| **Sync** | SD card CSV file download via dedicated characteristics | Auto-stream on Sync characteristic during reconnect (firmware-driven) + manual BLE sync via `StartBleSync (0x16)` (replaces SD card flow on V2)                                              |
| **Session config** | Multiple sequential `HexMessagesBuilder` writes (location, time, mode) | Single binary command `NewSessionConfig (0x13)`                                                                                                                                             |
| **Time sync** | Date string in `dd/MM/yy-HH:mm:ss` format | Unix epoch i64, sent at connection via `SetTime (0x15)`. Mobile sessions only: re-sent every hour. Fixed sessions: firmware gets time from WiFi POST `X-Server-Time` header.                |
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

> Optionally read the standard GATT **Firmware Revision String** characteristic (`0x2A26`) after V2 service discovery and log it. Android commit `974a12652` added this for diagnostics — useful when QA reports protocol-level oddities.

---

## 2. BLE GATT Infrastructure (V2)

The device acts as a peripheral BLE GATT Server.

**Service UUID:** `a0e1f000-0001-4b3c-8e9a-1f2d3c4b5a60`

**Characteristics:**

| Name            | UUID | Permissions | Description |
|-----------------| ---- | ----------- | ----------- |
| **Status**      | `a0e1f000-0002-4b3c-8e9a-1f2d3c4b5a60` | Notify | Device sends its state (Idle, Running, HasSavedSession, ReadyToSync) + battery level. |
| **Command**     | `a0e1f000-0003-4b3c-8e9a-1f2d3c4b5a60` | Write | App writes binary `AppCommand`s (little-endian byte streams). |
| **Response**    | `a0e1f000-0004-4b3c-8e9a-1f2d3c4b5a60` | Notify | Device sends replies: Ack, Nack, Ready, SensorInfo, SyncInfo. |
| **Measurement** | `a0e1f000-0005-4b3c-8e9a-1f2d3c4b5a60` | Indicate | Live measurement stream during active session. |
| **Sync**        | `a0e1f000-0006-4b3c-8e9a-1f2d3c4b5a60` | Indicate | Two flows share this characteristic: (a) firmware auto-stream of stored measurements after reconnect of an active session, (b) BLE manual sync via `StartBleSync (0x16)`. |

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
- `0x01` **HasSavedSession**: Payload = `[0x01, battery_level_u8, session_uuid_16B_LE, has_measurements_u8_bool, file_size_u64_LE]` (27 bytes; FW commit `3990cf22`). `file_size` is the byte length of the unsynced measurements file on the device — feed it to a sync-ETA helper (see §9 `estimateSyncSeconds`) so the "sync before new session" / "sync before finish" dialogs can show an ETA before the user starts. Falls back to 0 on metadata failure or when `has_measurements` is false. **Older firmware** emits the original 19-byte payload — short-read `file_size` as 0 in that case and omit the ETA hint.
- `0x02` **Running**: Payload = `[0x02, battery_level_u8, session_uuid_16B_LE]` (18 bytes). Session actively running. **No `has_measurements` byte and no `file_size` here** — drain status during a running session must be detected another way (see §9).
- `0x03` **ReadyToSync**: Payload = `[0x03, file_size_u64_LE (8B), utf8_password_bytes...]` (FW commit `ed751b180`). Emitted while a manual sync (`StartBleSync 0x16` or the legacy `StartWiFiSync 0x12`) is in progress and the firmware has opened the SoftAP / readied the stream. `file_size` is the byte length of the upcoming `/sync` body (legacy WiFi path) **or** the on-disk littlefs file size (BLE path); the app uses it to drive a 0..100% progress UI shared across all manual-sync entry points. Password is variable-length UTF-8, no terminator (zero-length on the BLE path). **Important:** this status has no battery byte at offset 1 — parsers must short-circuit before generic battery decoding.

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
- In every Status notification (Idle, HasSavedSession, Running)
- Updated with each live measurement sent (Status is re-notified alongside Measurement indications)
- **NOT** present in `ReadyToSync (0x03)` — short-circuit before generic battery decoding for that opcode

This replaces the old separate battery characteristic (`0000ffe7`).

### App Behavior per Status

| Status | Mobile Session | Fixed Session |
| ------ | -------------- | ------------- |
| **Idle** | Start new session via `NewSessionConfig` | Start new session via `NewSessionConfig` |
| **HasSavedSession** | **Reconnection path:** send `ContinueSession (0x10)` — device transitions to Running and streams both sync + live data. **New-session path:** offer the user **Sync** (via `StartBleSync 0x16`) / **Discard** (via `DiscardSession 0x11`) / **Cancel** before `NewSessionConfig`. The `file_size` byte gives an ETA hint for the sync option. | N/A (fixed sessions don't reconnect this way; firmware auto-resumes via WiFi — see §6b) |
| **Running** | Sync + live data flow automatically (interleaved) on the BLE Sync + Measurement characteristics. No command needed. | Measurements flow **server-side over WiFi**, not over BLE. The app does NOT need to subscribe to BLE Measurement / Sync to receive them — they appear on the AirCasting backend. BLE is only used for status / stop / reconfigure. |
| **ReadyToSync** | Internal to the manual-sync flow — the app should already be driving it; just parse `file_size` for progress UI. | Not applicable. |

**Note:** On `HasSavedSession` the app picks `ContinueSession` (resume), `StartBleSync` (sync first, then optionally new session), or `DiscardSession` (wipe + new session). For `Running` (mobile, phone went out of range), Sync + Live both stream automatically on BLE reconnection — no command needed.

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
    - `0x06`: **SyncFailed** — emitted by the BLE manual sync flow (`StartBleSync 0x16`) when an indication on the Sync characteristic fails to ACK. Firmware stops the loop; app surfaces a sync-failure dialog and **leaves records on the device for a retry** (firmware does not wipe).
- `0x22` **Ready**: Procedure complete (e.g., WiFi connected, sync finished, storage cleared). For a running fixed session, firmware also emits `Ready` after **every successful measurement POST** while BLE is connected — i.e. it doubles as a per-measurement heartbeat. The app must treat repeated `Ready` as idempotent: the first one completes the configure flow / kicks off setup work; subsequent ones are heartbeat-only and must not re-trigger setup.
- `0x23` **SensorInfo**: Response to `GetSensors`. Bytes after `0x23` = ASCII string `"PM1,μg/m3;PM2.5,μg/m3"`.
- `0x24` **SyncInfo**: Response to the legacy WiFi-SoftAP `StartWiFiSync (0x12)` path. Bytes after `0x24` = `32B_WiFi_SSID_string` + `64B_WiFi_Password_string` (null-padded). **Not emitted by the BLE `StartBleSync (0x16)` path** — for BLE manual sync, the password is delivered via `Status::ReadyToSync (0x03)` instead, and on the BLE path it is empty.

### iOS dispatch pattern

Maintain a `pendingCommand` enum / completion-handler dictionary keyed by the opcode you wrote. When a Response notification arrives, decode the first byte, dispatch to the registered handler, and clear it once `Ready` (terminal) arrives. For commands with an Ack-then-Ready two-stage protocol (`NewSessionConfig`, `StartBleSync`), do not invoke the user-visible completion until `Ready` lands. Android commit `b266c57ab` corrected this — only `NewSessionConfig` / `ContinueSession` `Ready` should be treated as session-start; other `Ready`s (heartbeat, sync-done) must route to their own handlers.

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

> **Android caveat:** an older Android branch (`AirBeamMiniV2Configurator.kt:755-778`, commit `db3cebf24`) contained a `Nack(0x03 StorageHasMeasurements) → StartSync → retry ContinueSession` path. This is **incorrect** — firmware does not Nack `ContinueSession` for stored measurements; the path was added on a wrong assumption and is unreachable. Do **NOT** port it to iOS. If `Nack(0x03)` ever arrives on `ContinueSession`, treat it as an anomaly (log + surface to user); do not auto-send sync.

### B. `DiscardSession` (OpCode `0x11`)

**Payload:** Single byte `0x11`.
**Context:** Terminate session, wipe locally stored measurements. Also stops a running session.

- `Ack (0x20)`, then attempts wipe.
    - Success: `Ready (0x22)`.
    - Failure: `Nack (0x04 ClearStorageFailed)`.

**iOS wiring:** When the user stops a session (mobile or fixed), the V2 configurator must `writeValue(_:for:type:)` the `0x11` byte and then **wait for the `Ready (0x22)` response** before disconnecting (`cancelPeripheralConnection`). Use `.withResponse` write type and chain into the Response notification handler — disconnecting on the BLE write ack alone leaves the firmware in `Running` state. Android learned this in commits `a8f4a8c15` and `1b89ba35d`. Mirror in iOS by adding a `discardSession(completion:)` to the `AirBeamConfigurator` protocol with a default no-op (V1 does not need it) and a real implementation on `AirBeamMiniV2Configurator`.

**`DiscardSession` is honored mid-`StartBleSync`** — firmware still wipes if the user aborts mid-sync. This is the basis for the "Discard & Finish" escape on the sync-and-finish dialog (see §9).

### C. `StartWiFiSync` (OpCode `0x12`) — LEGACY (WiFi-SoftAP path, currently dormant)

**Payload:** Single byte `0x12`.
**Context:** Legacy WiFi-SoftAP manual file sync. Renamed from `StartSync` to `StartWiFiSync` in firmware once the BLE path (§5.C-BLE below, OpCode `0x16`) shipped. **Do NOT implement on iOS** — the BLE path is the production manual-sync mechanism. Documentation kept for reference / future revival only.

Sequence (for reference):
1. App writes `0x12` to Command. Device replies `Ack (0x20)` on Response.
2. Firmware opens SoftAP `"AirBeam Mini Sync"` (random WPA2 password) and an HTTP server.
3. Device notifies Status with `ReadyToSync (0x03) + file_size_u64_LE + utf8_password_bytes` (§3).
4. App joins the SoftAP using the password and `GET http://192.168.4.1/sync`.
5. Body is `application/octet-stream` containing the raw measurement file:
   concatenated blocks of `[0xAB, 0xBA, count_u8, count × 8B records, xor_u8]`.
   Each 8-byte record is `ts_u32_LE + pm1_u16_LE + pm25_u16_LE`. Total body length matches the BLE-side `file_size`, driving the 0..100% progress UI.
6. When the HTTP transfer completes, firmware emits `Ready (0x22)` on Response and automatically clears stored measurements via `storage.clear_measurements()`.

- Failure: `Nack (0x04)` (`SyncStorageFailed`/`ClearStorageFailed`).

The Android client retains `V2SyncOrchestrator` + `V2WifiApConnector` + `V2SyncFileDownloader` but does **not** invoke them. iOS should skip the WiFi path entirely.

### C-BLE. `StartBleSync` (OpCode `0x16`) — current manual-sync path

**Payload:** Single byte `0x16`.
**Context:** BLE-only manual sync. Firmware commits `e1a03b9415a8a4e70ee24acb824c1361f526d53c` and `c4dd9e62d5df599601d4edf57e5b8f5386440564`. This is the **production manual-sync path** and the only one iOS needs to implement.

Sequence:
1. App writes `0x16` to Command. Device replies `Ack (0x20)` on Response.
2. Device notifies Status `ReadyToSync (0x03)` with `file_size_u64_LE` + empty password (~100 ms before the first chunk; password byte field is present but zero-length on the BLE path — only `file_size` is meaningful).
3. Firmware sleeps ~100 ms to let the app finalize subscription state.
4. Firmware streams stored records on the **Sync characteristic** (indicate). Each indication payload matches the reconnect-time auto-sync format: `[count_u8, 2B padding, count × 8B records]` where each record is `ts_u32_LE + pm1_u16_LE + pm25_u16_LE`. Up to 30 records per indication.
5. When all records have been sent, firmware emits `Ready (0x22)` on Response, then **auto-clears storage and the saved session-config** in its main loop's Stop handler. **No `DiscardSession` is needed from the app afterwards.**
6. Failure: `Nack (0x06 SyncFailed)` if an indication does not ACK, or `Nack (0x04 ClearStorageFailed)` if the post-sync storage wipe fails. Firmware retains records on Nack so the app can retry.

**iOS implementation notes:**
- New opcode `OPCODE_START_BLE_SYNC = 0x16` on `AirBeamMiniV2Configurator`.
- New error code `NACK_SYNC_FAILED = 0x06`.
- The Sync-characteristic indication handler must route chunks to a **registered manual-sync handler** while a manual BLE sync is in flight — bypass the default reconnect-time DB save path so the manual-sync orchestrator can route mobile vs fixed records appropriately.
- No BLE disconnect/reconnect, no SoftAP, no `DiscardSession` on success — firmware handles cleanup itself.

**Progress UI:** firmware emits the `ReadyToSync (Status 0x03)` notification ~100 ms *before* the first Sync indication and uses the on-disk LittleFS file size (`std::fs::metadata(FILE_PATH).len()`, `.unwrap_or(1)` on metadata failure) as `file_size`. Each on-disk storage block is framed as `[0xAB, 0xBA, count_u8, count × 8B records, xor_u8]` = `5 + 8 × count` bytes, so the orchestrator increments `receivedBytes += 5 + 8 × chunk.size` per indication and computes `pct = receivedBytes * 100 / file_size` (clamped 0..99 mid-stream, set to 100 after `Ready 0x22`). **Critical:** the file-size collector must run in parallel so it is updated as soon as `ReadyToSync` lands — awaiting it after sending `StartBleSync` is too late (that call only resolves on the post-stream `Ready 0x22`, by which time every chunk has already arrived with `expectedSize == 0` and progress stays at 0%). On iOS, use a separate observer (e.g. another `NotificationCenter` subscription, a `@Published` property, or a parallel completion handler) seeded before the write.

### D. `NewSessionConfig` (OpCode `0x13`)

**Payload (Mobile):** `0x13` + `16B_UUID` + `2B_interval_seconds(u16)` + `0x01`
Mobile sessions do **not** include `session_token` — the field is absent from the payload entirely.

**Payload (Fixed):** `0x13` + `16B_UUID` + `2B_interval_seconds(u16)` + `0x00` + `1B_pm1_index` + `1B_pm2_5_index` + `16B_session_token` + `32B_WiFi_SSID` + `64B_WiFi_Password`
Total: 134 bytes. Strings are null-byte padded to their container lengths. **Byte 19 is the mode byte (0x00=FIXED, 0x01=MOBILE)** — the firmware reads this to distinguish session types, so the order matters. The `session_token` (16 bytes) comes AFTER the indices, not immediately after the UUID.

**Interval per session type:**
- **Mobile:** `interval_seconds = 1` (1 measurement per second) — default. User-configurable via the "Interval (seconds)" input on the New Session Details screen; integer ≥ 1 (Android commit `02d0baeba`).
- **Fixed:** `interval_seconds = 60` (1 measurement per minute) — fixed at 60s. Android originally exposed this as user-configurable too but reverted to a hard 60s default (commit `47c19f0aa`) because the BE polling cadence assumes 60s. iOS should follow suit: no interval input on the fixed-session screen.

The intervalSeconds value must thread from the session-details screen down through whatever the iOS session-creator pipeline is (e.g. `SessionContext` → `AirBeamFixedWifiSessionCreator` / mobile equivalent → `AirBeamMiniV2Configurator`). For non-V2 / V1 sessions, default to 1s mobile / 60s fixed in the configurator.

**Sparse-interval averaging gotcha.** AirCasting's averaging logic assumes the native sample rate is finer-grained than the averaging window. If a user picks a native interval ≥ a window size (e.g. 5s native and the FIRST 5s window, or anything ≥ 60s and the SECOND 60s window), each window holds ≤ 1 sample. The averaging pass then computes nothing meaningful, and any post-averaging `deleteLeftoverMeasurements` sweep can wipe out the rows it just "averaged" — leaving the session card with empty `measurements`: graph/map/share/upload all fail silently.

Android fix (commit `c4cdd9b9a`, DB migration `MIGRATION_36_37`, schema v37): persist the native interval per session on a nullable `sessions.measurement_interval` (INTEGER) column. The averaging service then **skips averaging for any window where `nativeInterval >= window.value`**:
- A 1s session averages at both FIRST(5s) and SECOND(60s).
- A 5s session skips FIRST(5s) but runs SECOND(60s).
- A ≥60s session skips both — periodic averaging is not scheduled at all.

iOS equivalent: add `measurementInterval: Int16?` (nullable, default null = legacy/V1 = 1s native) to the `Session` Core Data entity via lightweight migration. Apply the same per-window skip rule in whatever iOS averaging service exists (or check first whether iOS has an equivalent averaging service — if not, leave the column for future use and gate periodic averaging scheduling on `nativeInterval < secondWindow.value`).

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

### SD-Sync Wizard "Unplug Your AirBeam" Screen

V2 has no SD card → no unplug step needed. The wizard equivalent on iOS is:
- **Skipped entirely on V2** — go straight to the post-sync continuation (TurnOffLocationServices or finish).
- **Moved to AFTER the "successfully synced" screen on V1** — previously shown before device selection; on Android it now appears after the user taps Continue on the synced screen. Apply the same reordering on iOS (commit `dcef0b695`).

The V2 flag plumbs through the sync-finished event so the wizard controller knows to skip / reorder.

### Mapping to the iOS measurement persistence layer

The V2 binary format does NOT include sensor metadata (package name, thresholds, etc.) like the old ASCII format. The V2 configurator must construct the equivalent of `ABMeasurementStream` using:
- Sensor info from `GetSensors` response: `"PM1,μg/m3;PM2.5,μg/m3"`
- Hardcoded thresholds matching the AirBeam Mini sensor profile (lift them from `AirBeam3Configurator` / the V1 stream definitions to keep parity)
- Device ID from the connected `BluetoothDevice`

Persist via `MeasurementsSavingService` directly (do NOT route V2 live measurements through the EventBus-style `NewMeasurementEvent` analog if iOS has one — V2 owns its own DB writes). For UI refresh, post a notification (e.g., `NotificationCenter`) so `SessionDetailsViewController` and the live-streaming graph update on each measurement. Android learned this in commit `3d69a19c3`.

The old `AirbeamMeasurementsRecordingServices` (semicolon-string parser) is **not reusable** for V2 — a new binary parser is needed.

> **DB integrity tip:** Android added a **unique index on `measurements(session_id, stream_id, time)`** (commit `357d4002c`) so retries of the manual-sync stream cannot duplicate rows. Add the equivalent constraint on the iOS `Measurement` Core Data entity (unique constraint on the tuple).

---

## 6a. Fixed Session — WiFi-Drop Storage & Replay

When a fixed session is running and WiFi drops (or fails to connect), the firmware does NOT lose measurements. Storage replay is a **firmware-side concern handled over WiFi** — the app does not participate.

1. `send_measurement` (fixed path) POSTs to `/api/v3/fixed_sessions/{uuid}/measurements` via `wifi_manager.send_measurements(...)`.
2. If WiFi is not connected, the record is persisted to littlefs storage (`src/main.rs:171-175`).
3. Every main-loop tick (100 ms), if `storage.has_measurements() && wifi_manager.is_connected()`, firmware replays stored records through the WiFi POST endpoint via `sync_from_storage` (`src/main.rs:198-204`, closure routes FIXED → WiFi, MOBILE → BLE).
4. The WiFi POST response includes an `X-Server-Time` header parsed into `LoopEvent::TimeUpdate`, keeping the device clock server-authoritative. `SetTime` BLE hourly scheduling remains unused for fixed sessions.
5. `connected()` predicate in the main loop is WiFi for FIXED, BLE for MOBILE — so sync loop only fires on the correct transport.

**First-measurement failure signalling (commit `25f94a1`):** On a freshly started fixed session, if the first measurement send fails AND BLE is still connected, firmware emits `Nack(0x02 InvalidConfig)` and stops the loop — a hint to the app that WiFi creds/connectivity are bad. Suppressed on resumed sessions (see §6b).

---

## 6b. Fixed Session — Firmware-Side Resume (No App Required)

Commit `25f94a1` added autonomous resume for fixed sessions:

- On BLE setup timeout, if a saved FIXED session exists on the device, firmware auto-reconnects WiFi and returns `SetupResult::Continue`. The session keeps running **without the app**.
- First-measurement WiFi failure signalling is suppressed in this resumed path (avoid re-prompting creds on every power-cycle).

### iOS Implication

On BLE reconnect to a fixed-session device:
- Status notification may be `Running (0x02)` with a session UUID the app already knows — treat as normal continuation.
- Do NOT assume "no session running" just because the app wasn't involved in the latest setup. Always trust Status.
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

> **Stop foreground/recording services after fixed configure success** so the app does not retain BLE / power-hungry components for a WiFi-only session. Android commit `4e3ee96c4`.

---

## 8. `SetTime` Periodic Scheduling

`SetTime (0x15)` must be sent:
1. Immediately after connection (once Status is received)
2. Every hour while connected — **only for mobile sessions**. Fixed sessions get time from the backend server: the WiFi POST to `/api/v3/fixed_sessions/{uuid}/measurements` returns an `X-Server-Time` header that firmware parses into an internal `TimeUpdate` event (guarded by a ≥60s delta to avoid clock thrash). App must NOT schedule hourly `SetTime` for fixed sessions.

Use a `Timer` on the configurator instance (1-hour period). The command does not produce an Ack response — fire-and-forget write with `.withoutResponse`.

---

## 8a. Backend Timestamp Convention (Round-Trip)

The AirCasting BE persists session/measurement timestamps using a **"local wall-clock numerals treated as UTC"** convention, not real UTC. Failing to match it on either parse or upload produces an offset on the dashboard card and graph. This applies to fixed sessions; mobile sessions don't hit the V3 fixed-polling endpoint and are not affected.

Mechanism on BE (`HabitatMap/AirCasting`):
- `Session#start_time_local` / `end_time_local` use `skip_time_zone_conversion_for_attributes`. `TimeToLocalInUTC.convert` strips the offset on assignment, so the column stores the local wall-clock numerals as-is.
- `Measurement#time` on the V3 binary ingester path is written via `Utils.to_local_as_utc(epoch, session.time_zone)` — same convention.
- `FixedPolling::Serializer` / `Session#as_json` serialize via `iso8601(3)`, appending a literal `"Z"` suffix. The `Z` is misleading: the numerals are the session's local wall clock, not real UTC.

The wall clock is the session's `time_zone` column on BE.
- **Mapped (outdoor) fixed sessions** (`is_indoor == false`): BE looks up the TZ from `latitude` / `longitude` — usually ≈ the phone-default TZ in normal use, so phone-default parsing/formatting works end-to-end.
- **Indoor / locationless fixed sessions** (`is_indoor == true`): BE has no coordinates → `session.time_zone` defaults to `UTC`. The wall-clock numerals BE writes (notably for `Measurement#time` and `Session#end_time` updated from measurement ingest) are UTC. The app must parse/format those timestamps **as UTC, not phone-default**, or the graph and end-time drift by the phone-TZ offset.

Required app handling (every BE-facing fixed-session timestamp): use phone-default TZ when `is_indoor == false`, UTC when `is_indoor == true`. Android centralizes this in `DownloadMeasurementsService.beTimeZone(isIndoor)`.

Affected sites on iOS (mirror per the same rule):
- Session-download parsing of `start_time` / `end_time` — key on `sessionResponse.is_indoor`.
- Measurement-download parsing — key on `dbSession.is_indoor`; thread the TZ into the measurement factory.
- The "since" cursor sent to the V3 measurements polling endpoint — format with the same indoor-aware TZ so it matches BE's stored numerals (Android commits `f1fe732d4`, `fa52f77f0`).
- Session-params upload (V1) — phone-default TZ (BE strips offset on assignment regardless of session TZ).
- Any gzipped-JSON `Date` adapter (V1 measurement uploads, fixed-session params): leave at JVM/iOS default; pinning to UTC silently re-breaks the round-trip.

V2 binary measurement uploads (`POST /api/v3/fixed_sessions/{uuid}/measurements`) send `u32` epoch seconds directly; BE applies `to_local_as_utc` itself, so no app-side TZ handling is needed on the upload side — but the resulting `Measurement#time` and `end_time_local` BE writes use the session-TZ wall-clock convention, which is why the **download/parse side** must match.

Android commits for reference: `0d148625c`, `338c2b1f1`, `9999289ce`, `ffc79d2bf`, `3695d71c6`, `b21931159`, `fa52f77f0`, `f1fe732d4`.

Use `Locale(identifier: "en_US_POSIX")` for any custom `DateFormatter` parsing fixed BE timestamps (equivalent of Android's `Locale.US`) — pattern symbols / ASCII digits regardless of device locale.

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
4. When all stored data is streamed, no explicit "drain complete" Status flips — drain is detected via an idle-timeout on Sync indications (see "Drain detection" below).

### Scenario B: Device was power-cycled (HasSavedSession)

The device was turned off and back on. On BLE reconnect:
1. Status notification = `HasSavedSession (0x01)` with `has_measurements` flag and `file_size`
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

### Session UUID Validation for Sync Data

When sync measurements arrive on the Sync characteristic, **always verify the device's session UUID** (from the last Status notification, stored as `savedSessionUuid` on the V2 configurator) matches the current app session UUID before saving. If they don't match, the sync data is from an older session that the device still had in storage — **discard it**. Android commit `18e16b89f`.

The device UUID arrives in LE-encoded form and must be decoded with `UUID.fromLEBytes(...)` (see §5 helper) before comparing to the Core Data session UUID.

### Live Measurements — Direct DB Save + UI Notification

V2 saves live measurements **directly** through `MeasurementsSavingService`, using the device timestamp from the binary packet and the full device ID from the V2 configurator. Skip whatever EventBus-style observer flow the V1 path uses for mobile sessions — V2 owns its own writes; UI notification is a separate concern (post a `NotificationCenter` event so the live graph and active controllers refresh). Android commits `3d69a19c3` and `18e16b89f` for context.

> **Don't drop sync rows that pre-date the latest live row.** Android initially filtered synced records on `timestamp > lastMeasurementTime`, which silently dropped backfill rows when a live measurement arrived first during interleaving. Fixed in commit `a76d43451` — the unique index on `(session_id, stream_id, time)` (commit `357d4002c`) is the dedupe primitive; don't filter on timestamp ordering.

### Drain detection (Active sync)

The `Running (0x02)` Status payload is only 18 bytes (`[opcode, battery, uuid_16B]`) — it does **not** include a `has_measurements` byte. So `hasSavedMeasurements` from the most recent Status is only meaningful when the device was last seen in `HasSavedSession`; during an active mobile session you cannot read drain state off Status.

Compensate by tracking an **active-sync-draining flag** on the V2 configurator (Android commit `daf8cef01`):
- On every Sync (`0006`) indication, set `isActiveSyncDraining = true` and (re)schedule an idle timer.
- After 3 s of no further chunks (`SYNC_DRAIN_IDLE_TIMEOUT_MS`), flip the flag back to `false`.
- Surface this as a published / observable property so the UI can react.

### Sync Confirmation Dialogs

V2 introduces three entry points that gate on "unsynced measurements exist":

1. **Start path (`SyncBeforeNewV2SessionDialog`)** — user picks a V2 device that's in `HasSavedSession` and wants to start a *new* session. Offer **Sync** (drives `StartBleSync 0x16`), **Discard** (drives `DiscardSession 0x11`), or **Cancel**. Use `file_size` from the Status payload to show an ETA hint (e.g. `~estimateSyncSeconds(fileSize)`).
2. **Finish path (`SyncAndFinishV2SessionDialog`)** — user taps "Finish recording" during an active mobile session. The standard `FinishSessionConfirmationDialog` shows first to confirm intent. If `hasSavedMeasurements || isActiveSyncDraining` was true **at confirm-time** (re-evaluate at confirm, not at button-tap — commit `991f6f6e4`), the confirmation's `onConfirmed` callback dismisses and presents the sync-and-finish dialog (chained, not replacing). Otherwise the standard `StopRecordingEvent` path runs.
3. **Disconnected-view path** — same chained dialog from the disconnected-session view.

`SyncAndFinishV2SessionDialog` behavior (Android commits `886058649`, `3526b79f8`, `2425b0be3`):
- Non-cancelable.
- Auto-starts `StartBleSync (0x16)` on open (so `ReadyToSync (0x03)` lands ~100 ms later with `file_size` — fresh ETA even when the user opened the dialog from a `Running` Status that lacked the suffix).
- Shows progress percent during the stream.
- "Discard & Finish" cancels the orchestrator's job mid-stream; firmware honors `DiscardSession (0x11)` even with `StartBleSync` in flight, wiping on-device storage. Records collected so far are **not** inserted into the DB on this branch.
- On success: insert records, mark session FINISHED, push to backend on confirm. The trailing `0x11` is a no-op (firmware already auto-cleared storage on its `Ready 0x22` Stop-handler path).
- On failure (`Nack 0x06 SyncFailed`): show error; on confirm, post `StopRecordingEvent` — the `0x11` write then wipes the on-device data.

> **Show the sync-ETA hint as the dialog description**, formatted with localized "min." / "sec." (Android commits `cdc938108`, `0b23711fa`, `340e677c9`, `376f91c81`). Calibrate `BYTES_PER_SECOND` constant ≈ 1700 on Android (commit `c356f630d`); re-calibrate on iOS once the BLE throughput baseline is known.

### Discard before new session

When the user starts a new V2 mobile session and the device is in `HasSavedSession` and chooses the **Discard** branch, send `DiscardSession (0x11)` first to wipe the stored session, wait for `Ready`, then send `NewSessionConfig`. Android commit `ac5925900`.

After the start-path `SyncBeforeNewV2SessionDialog` completes a **sync**, **keep the BLE link open** and reuse it for `NewSessionConfig` — do not bounce the connection (Android commit `83abfb408`).

---

## 10. Error Surfacing

V2 introduces several distinct failure modes that the app must surface clearly:

- `Nack(0x02 InvalidConfig)` — show a generic "Could not configure session" dialog
- `Nack(0x05 InvalidWifiCredentials)` — show a "WiFi credentials wrong, please re-enter" dialog and route the user back to the WiFi entry screen
- `Nack(0x03 StorageHasMeasurements)` on `ContinueSession` — should not occur per firmware design. If it does occur, treat as anomaly: log and surface a generic error. Do NOT auto-send sync.
- `Nack(0x01 NoSession)` — silent; treat as Idle and proceed
- `Nack(0x04 ClearStorageFailed)` — log; the next connection will retry
- `Nack(0x06 SyncFailed)` (BLE manual sync) — surface a sync-failure dialog and route the user to retry / discard. Records remain on the device.

Use a single dialog component (mirror Android `d6749096e` which switched from Toast to dialog) and **lock it down** so the user can't accidentally bypass on fixed-session configure failure (Android commit `3708d75e4`). On iOS this is a `UIAlertController` with a single OK action and `isModalInPresentation = true` on the wrapping VC, or a SwiftUI `.alert` bound to a non-dismissable state.

Block the "Start Recording" button on fixed-session configure outcome — don't let the user start two sessions in flight (Android commit `73cf51072`).

---

## 11. Reference: Files to Create / Modify on iOS

### New files (V2-only)
- `AirCasting/ABConnector/V2/AirBeamMiniV2Configurator.swift` — implements `AirBeamConfigurator`; owns Status/Command/Response/Measurement/Sync subscriptions, command writes, response dispatch, `SetTime` timer, `discardSession`
- `AirCasting/ABConnector/V2/V2BinaryProtocol.swift` — opcodes, payload builders, response parsers, UUID LE helpers, battery decoder
- `AirCasting/ABConnector/V2/V2MeasurementParser.swift` — live + sync chunk parsers
- `AirCasting/ABConnector/V2/V2ResponseDispatcher.swift` — registers per-opcode completion handlers; routes Ack / Nack / Ready / SensorInfo / SyncInfo
- `AirCasting/ABConnector/V2/V2BleSyncOrchestrator.swift` — drives `StartBleSync (0x16)` flow: writes opcode, observes `ReadyToSync` file_size in parallel, accumulates chunks, computes progress, settles on `Ready (0x22)` or `Nack (0x04/0x06)`
- `AirCasting/ABConnector/V2/V2StateRepository.swift` — observable state for the V2 configurator (`hasSavedMeasurements`, `isActiveSyncDraining`, `readyToSyncFileSize`, `syncProgress`)
- `AirCasting/SDSync/V2/V2FixedSessionAPIService.swift` — `POST /api/v3/fixed_sessions` typed Decodable round-trip
- `AirCasting/CreateSessionViews/V2/SyncBeforeNewV2SessionDialog.swift` — pre-start unsynced-measurements dialog (Sync / Discard / Cancel)
- `AirCasting/BluetoothSession/V2/SyncAndFinishV2SessionDialog.swift` — finish-path sync-and-finish dialog (auto-start sync, mid-stream Discard & Finish)

### Modified files
- `AirCasting/Utils/Bluetooth/BluetoothManager.swift` — read advertised service UUIDs at scan time, set `firmwareVersion` on `BluetoothDevice`
- `AirCasting/Utils/Bluetooth/BluetoothDevice.swift` — add `firmwareVersion` property + `FirmwareVersion` enum
- `AirCasting/AppDelegate+Injection.swift` — register `AirBeamConfigurator` factory branching on `firmwareVersion`
- `AirCasting/ABConnector/AirBeamConnectionController.swift` — pass `firmwareVersion` through; stamp it on the device after successful V2 GATT discovery
- `AirCasting/ABConnector/AirBeamConfigurator` protocol — add `func discardSession(completion: @escaping (Result<Void, Error>) -> Void)` with default no-op
- `AirCasting/BluetoothSession/BluetoothSessionRecordingController.swift` (+ `MobileAirBeamSessionRecordingController`) — call `discardSession` on stop for V2; skip the V1 measurement-observer pipeline for V2; gate finish on `SyncAndFinishV2SessionDialog` when drain is active
- `AirCasting/BluetoothSession/ReconnectionController.swift` — handle V2 `HasSavedSession` → `ContinueSession`; defer until Status arrives (Android commit `2ae1e99fa`)
- `AirCasting/APICommunicator/APIClient.swift` — ensure `https://` + port 443 default
- `AirCasting/Models/SessionContext.swift` / `AirBeamFixedWifiSessionCreator.swift` — branch on V2: call `V2FixedSessionAPIService` and pass response into `AirBeamMiniV2Configurator.startFixedSession(...)`
- `Session` Core Data entity — add `measurementInterval: Int16?` (lightweight migration) for the sparse-interval averaging gate (see §5.D)
- `Measurement` Core Data entity — add unique constraint on `(session, stream, time)` (Android commit `357d4002c`)
- SD-sync wizard controller — skip the "Unplug AirBeam" step on V2; reorder it to post-sync on V1 (Android commit `dcef0b695`)

### Untouched (V1)
- `AirBeam3Configurator.swift`, `HexMessagesBuilder.swift`, `MeasurementsRecordingServices.swift`, `SDCardAirBeamServices.swift`, `MiniSDCardMeasurementsParser.swift`, `MiniSDSyncFileFactory.swift`, `SDSyncController.swift`, `UploadFixedSessionAPIService.swift` — all stay as-is.

### Skip on iOS
- The legacy WiFi-SoftAP manual sync path (`StartWiFiSync 0x12`, `V2SyncOrchestrator`, `V2WifiApConnector`, `V2SyncFileDownloader` in Android) — Android keeps the code dormant; iOS should not implement it at all. Manual sync on iOS is BLE-only via `StartBleSync (0x16)`.

---

## 12. V2 → V1 Firmware Fallback (Hardware-Mixed Fleet)

If a user has both V1 and V2 Airbeam Minis paired, the app may attempt a V2 GATT connect on a V1 device. The V2 service won't be present, GATT discovery returns no V2 characteristics, and the configurator must transition the connection to the V1 path **without tearing down session-recording state**.

Android learned several painful lessons here that iOS will largely sidestep — `CBCentralManager` exposes failure paths differently from Nordic 2.x — but the **principles** apply:

1. **Distinguish "service not supported" from "real disconnect."** On Android's Nordic stack, "V2 service missing" surfaces as `ConnectionObserver.onDeviceDisconnected(reason=REASON_NOT_SUPPORTED)` and **also** as a `.fail` callback ~15 ms later. iOS doesn't have that duality, but the analogous pitfall is: don't run the standard disconnect teardown (post unexpected-disconnect notifications, stop the recording service, unsubscribe from EventBus) on a "no V2 service" path, or the V1 fallback connect will succeed but the session-recording machinery will be gone.
2. **Capture the V2/V1 leg at closure-creation time.** When the fallback connector queues a V2 attempt followed by a V1 attempt, any failure-callback closure on the V2 attempt must close over a captured `isV2Leg = true` rather than reading a mutable "current attempt" field at callback time — by the time the late V2 callback fires, the field has flipped to V1 and the late V2 failure gets misrouted into the V1 failure branch, which can post a connection-failed event mid-V1-connect and tear V1 down. Android commit `67656474d`.
3. **Idempotent per-leg failure callbacks.** Guard against duplicate V2-failure / V1-failure callbacks (Android `v2FailureHandled` / `v1FailureHandled` flags, commit `9b6dbd044`).
4. **Reset V2 BleManager state explicitly** before starting the V1 attempt — clear the V2 configurator's characteristics, jobs, and `V2StateRepository` so a later real V2 reconnect doesn't see stale state (Android commit `484cd11e4`).

Reference commits: `9033d2640`, `62ddc827a`, `484cd11e4`, `9b6dbd044`, `67656474d`, `f38cb2089`.

> If iOS does **not** support mixed V1/V2 Mini in the same session-creation flow (e.g. firmware version is committed at scan time and there's no fallback connector), this whole section can be deferred. The principles are still worth keeping in mind for any future "service not present" handling.

---

## 13. Reconnection Hardening

Mobile-session reconnection (Phase 3) needs several hardening fixes that Android arrived at iteratively:

- **No hard cap on retries** — let the reconnect loop run as long as the user expects (Android commit `c31e1797e`). Surface "still reconnecting…" UI rather than a permanent failure.
- **Route `.fail` callbacks to a connection-failed path, not the disconnect path** — disconnect handlers tear down state machinery that the next attempt needs (Android commit `b838eb4f6`).
- **Guard against stale state-flow observers** — when a new connector instance is created, cancel previous observer coroutines / Combine subscriptions so the new instance owns the stream (Android commits `57154f2df`, `17f6182bb`, `8e6ade2fc`).
- **Use a coroutine/async delay, not a blocking sleep** between retries (Android commit `2b9502e1e`). On iOS, `Task.sleep(nanoseconds:)` or a `DispatchQueue` delay.
- **Finalize with an error when retries exhaust** (Android commit `ca5988b35`).
- **Add `[RECONNECT]` log tags** across the path for support (Android commit `b8787fbc6`).

---

## 14. Cross-reference: Android commits for each behavior

When in doubt, read the Android implementation in https://github.com/HabitatMap/AircastingAndroid/tree/dev. All commits below are reachable from `origin/dev`:

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
| Block Start Recording on fixed configure outcome | `73cf51072`, `c821f623f` |
| Disconnect BLE on fixed V2 success + lock down dialog | `3708d75e4` |
| Stop foreground services after fixed configure success | `4e3ee96c4` |
| Keep local row on configure failure | `dd05d7989` |
| Toast → Dialog | `d6749096e` |
| Live-graph update during V2 recording | `3d69a19c3` |
| Single error dialog on fixed-config failure | `bd92f041b` |
| Treat only NewSessionConfig/ContinueSession Ready as session-start | `b266c57ab` |
| HTTPS / port 443 | `caf2dc3b0`, `39c0a59b0` |
| V3 endpoint typed deserialization | `448cff1a5` |
| Session_token little-endian | `97bbe0f38` |
| Fixed interval 60s (hard-coded, no UI) | `7659eeb01`, `47c19f0aa` |
| User-configurable mobile interval | `02d0baeba` |
| Sparse-interval averaging gate (DB v37) | `c4cdd9b9a` |
| Parse fixed end_time as UTC (legacy) | `b21931159` |
| Indoor BE-timestamp UTC round-trip | `0d148625c`, `338c2b1f1`, `9999289ce`, `ffc79d2bf`, `fa52f77f0`, `f1fe732d4` |
| Sync UUID validation + direct DB save | `18e16b89f`, `489902d59` |
| Don't drop synced records that predate latest live row | `a76d43451` |
| Unique index on (session_id, stream_id, time) | `357d4002c` |
| Discard before new session | `ac5925900` |
| `ContinueSession` Nack(0x03) auto-recover via StartSync (INCORRECT — do not port) | `db3cebf24` |
| Stamp `FirmwareVersion.V2` on successful V2 connection | `bf0325243` |
| Read Status to recover missed notification | `9ec55ffb2` |
| Battery as signed i8 | `ab84c44f6` |
| Defer reconnect until Status arrives | `2ae1e99fa` |
| Surface V2 Nack errors + handle Nack(0x03) | `884cbd24b` |
| Sync dialogs (start + finish + disconnected) | `b7e2c2ca2`, `3086e1dc0`, `a586b0702` |
| Off-by-one indexOfPresenter crash on first measurement | `d35b566e6` |
| Skip unplug screen for V2; reorder for V1 | `dcef0b695` |
| BLE manual sync (`StartBleSync 0x16`) | `975ca4c9b` |
| Manual-sync progress UI via ReadyToSync.file_size | `c91f5bb4a`, `19e2e4b05` |
| Manual-sync ETA description / formatting / i18n | `cdc938108`, `c356f630d`, `0b23711fa`, `340e677c9`, `376f91c81` |
| Drain detection via 0006 indications | `daf8cef01` |
| Drain-aware finish dialog | `886058649`, `3526b79f8`, `2425b0be3`, `7e05a35e8`, `2ab5f4377`, `991f6f6e4` |
| Mark mobile session FINISHED + push to backend after sync | `87fe4fa39`, `f1fe732d4` (parts) |
| Keep BLE link after post-sync Discard for new-session | `83abfb408` |
| Drive new-session HasMeasurements sync from dialog | `7e4115d0b` |
| Log FW version from GATT 0x2A26 | `974a12652` |
| V2→V1 fallback: Nordic disconnect-path + leg tagging + dedupe | `9033d2640`, `62ddc827a`, `484cd11e4`, `9b6dbd044`, `67656474d`, `f38cb2089` |
| Reconnect hardening (loop, observers, sleep→delay) | `c31e1797e`, `b838eb4f6`, `b8787fbc6`, `57154f2df`, `ca5988b35`, `2b9502e1e`, `17f6182bb`, `8e6ade2fc` |
| Active sessions DB writes parity for synced rows | `a6af1ee59` |
| Bluetooth on/off cycle reconnect | `8ac3349b3` |
| Drop duplicate disconnect events on connect retries | `6bef8ab73` |
| Live-graph fallback when no entries | `c071e441a` |
| Foreground-service teardown debug → cleanup | `53aeb054d` (debug only — do not port) |
| Silence foreground service notification | `83715a087` (Android-only) |
