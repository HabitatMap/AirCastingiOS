# Airbeam Mini V2 — iOS Implementation Phases

Phased plan for porting V2 firmware support to `HabitatMap/AirCastingiOS`. Each phase is shippable in isolation and leaves V1 fully intact. Phase boundaries mirror the Android rollout (commits since `9c91d24856e0be6bd5794a0ef2b74a3cce5ceed5`) so Android source can be referenced 1:1 while implementing.

Always read `.claude/ble_mobile_app_guide_ios.md` alongside this file — it has the protocol details. This file is the **work breakdown**.

**Reference repos:**
- Android implementation: https://github.com/HabitatMap/AircastingAndroid/tree/feat/ab-integration
- Firmware: https://github.com/HabitatMap/AirbeamMiniFirmware

**Out of scope until firmware support lands:** the full-file `StartSync (0x12)` flow (SD-sync replacement + pre-new-session "sync first?" path). The **active sync** during mobile reconnection (firmware-driven, on the Sync characteristic) IS in scope and is covered in Phase 3.

---

## Phase 0 — Scaffolding (½ day)

**Goal:** Carve out a V2 namespace without changing behavior.

**Tasks**
- [ ] Create `AirCasting/ABConnector/V2/` group/folder
- [ ] Add `FirmwareVersion` enum (`v1`, `v2`) in `AirCasting/Utils/Bluetooth/`
- [ ] Add `firmwareVersion: FirmwareVersion` property to the `BluetoothDevice` protocol (default `.v1`) and the concrete `CBPeripheral`-backed implementation
- [ ] Define empty `AirBeamMiniV2Configurator: AirBeamConfigurator` stub conforming to existing protocol
- [ ] Update `AppDelegate+Injection.swift` so `AirBeamConfigurator` resolution becomes a factory closure: `firmwareVersion == .v2` → V2 configurator (currently a no-op stub), else `AirBeam3Configurator` (V1 path unchanged)
- [ ] Add a default `discardSession(completion:)` to `AirBeamConfigurator` returning success — V1 stays a no-op

**Done when:** App still works exactly as before for V1 Mini. New `.v2` enum case exists but no device routes through V2 yet.

**Reference Android commit:** none (Android did this inline with Phase 1).

---

## Phase 1 — V2 BLE Connection Infrastructure (2–3 days)

**Goal:** Detect a V2 device, connect, subscribe to all 5 characteristics, decode Status, decode battery. No commands sent yet.

**Tasks**
- [ ] **Scan-time detection**: in `BluetoothManager.swift` `centralManager(_:didDiscover:advertisementData:rssi:)`, read `advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]` and stamp `firmwareVersion = .v2` on the discovered `BluetoothDevice` if it contains `a0e1f000-0001-...`
- [ ] **Connection-time confirmation**: re-stamp `firmwareVersion = .v2` after `peripheral(_:didDiscoverServices:)` confirms the V2 service. Persist on the `Device` Core Data entity (Android commit `bf0325243`)
- [ ] **GATT discovery in `AirBeamMiniV2Configurator`**: discover service `a0e1f000-0001-...`; discover all 5 characteristics; verify all present (fail connection otherwise)
- [ ] **Subscribe** to Status, Response, Measurement, Sync via `setNotifyValue(true, for:)`
- [ ] **300ms settle delay** before any command (`DispatchQueue.main.asyncAfter`)
- [ ] **Status decoder** in `V2BinaryProtocol.swift`:
  - `0x00` Idle → `(battery, isCharging)`
  - `0x01` HasSavedSession → `(battery, isCharging, sessionUUID, hasMeasurements)`
  - `0x02` Running → `(battery, isCharging, sessionUUID)`
- [ ] **Battery decoder**: `Int8(bitPattern: byte)`; `abs()` is %; sign is charging direction
- [ ] **UUID LE helpers**: `UUID.toLEBytes()` and `UUID.fromLEBytes(_:)` (see guide §5)
- [ ] **Status fallback read**: if no Status notification arrives within 1s of subscription, explicitly `readValue(for: statusCharacteristic)` (Android commit `9ec55ffb2`)
- [ ] **Reconnection plumbing**: ensure `ReconnectionController.swift` defers any V2 action until the first Status notification arrives (Android commit `2ae1e99fa`)

**Done when:** Plug in a V2 device, connect, observe correct Status state and battery % (incl. charging sign) in the UI / logs. No session can be started yet.

**Reference Android commits:** `f63f3abf3`, `bf0325243`, `9ec55ffb2`, `ab84c44f6`, `2ae1e99fa`, `8ac3349b3`, `6bef8ab73`.

---

## Phase 2 — V2 Mobile Session: Configure + Live Streaming (3–4 days)

**Goal:** Start a mobile session on a V2 device and stream live measurements directly to Core Data.

**Tasks**
- [ ] **Command writer** in `AirBeamMiniV2Configurator`: write opcode bytes via `peripheral.writeValue(_:for: commandChar, type: .withResponse)`
- [ ] **Response dispatcher** (`V2ResponseDispatcher.swift`):
  - First byte switch: `0x20 Ack`, `0x21 Nack(errorCode)`, `0x22 Ready`, `0x23 SensorInfo`, `0x24 SyncInfo`
  - Per-pending-command completion handlers; clear on terminal response
  - **Idempotent Ready**: track which `Ready` is "first" (completes setup) vs subsequent (heartbeat); only the first fires the user-visible callback (Android commit `913e1d58d`, `b266c57ab`)
- [ ] **`GetSensors (0x14)`** on connect → store `"PM1,μg/m3;PM2.5,μg/m3"` for stream metadata
- [ ] **`SetTime (0x15)`** on connect (immediate) and on a 1-hour `Timer` (mobile sessions only)
- [ ] **`DiscardSession (0x11)`** on Status = `HasSavedSession` before starting a new session (Android commit `ac5925900`)
- [ ] **`NewSessionConfig (0x13)` mobile payload** (build per guide §5.D):
  - `[0x13] + UUID_LE(16) + interval=1_LE(2) + 0x01` = 20 bytes total, NO session_token
  - Wait for `Ack` then `Ready` before signalling success
- [ ] **Live measurement parser** (`V2MeasurementParser.swift`): decode 9-byte indication
- [ ] **Direct DB save**: write to `MeasurementsSavingService` directly (V2 owns its writes); do NOT go through V1's measurement-observer pipeline for V2 mobile sessions (Android commit `18e16b89f`)
- [ ] **UI refresh notification**: post a `NotificationCenter` event so live-graph and active controllers refresh (Android commit `3d69a19c3`)
- [ ] **`DiscardSession` on stop**: when the user finishes the session, write `0x11` and **wait for `Ready`** before disconnecting (Android commits `a8f4a8c15`, `1b89ba35d`)
- [ ] **Error dialog**: surface `Nack` errors via a single `UIAlertController` (Android commits `884cbd24b`, `d6749096e`, `bd92f041b`)
- [ ] **Off-by-one fix**: when wiring V2 sensors into the live-graph presenter, double-check `indexOf` arithmetic (Android commit `d35b566e6` crashed on first measurement here)

**Done when:** Start a V2 mobile session, watch live PM1 / PM2.5 values stream, stop the session, verify the device returns to Idle on next connection.

**Reference Android commits:** `cd666ed21`, `884cbd24b`, `d35b566e6`, `913e1d58d`, `b266c57ab`, `d9a29f896`, `a862f1583`, `a8f4a8c15`, `1b89ba35d`, `ac5925900`, `8198f4445`, `3d69a19c3`, `18e16b89f`, `d6749096e`, `bd92f041b`.

---

## Phase 3 — V2 Mobile Session Reconnection + Sync (2–3 days)

**Goal:** Handle BLE reconnection mid-session; consume sync chunks from the device storage.

**Tasks**
- [ ] **Sync chunk parser**: 244-byte indication → `[count_u8, padding_2B, record_0(8B), ...]`; each record = `[ts_u32_LE, pm1_u16_LE, pm25_u16_LE]`
- [ ] **Per-chunk DB save**: write each chunk's records to Core Data immediately (do not accumulate)
- [ ] **Session UUID validation**: compare `savedSessionUuid` (decoded from last Status via `UUID.fromLEBytes`) to current app session UUID; if mismatch → **discard the chunk** (it's stale storage from an older session). Android commits `18e16b89f`, `489902d59`
- [ ] **Scenario A — Status `Running` on reconnect**: do nothing; chunks + live measurements stream automatically (interleaved); both must be parsed
- [ ] **Scenario B — Status `HasSavedSession` on reconnect**: send `ContinueSession (0x10)`; on `Ack` device transitions to Running and starts sync + live; same parsing as Scenario A
- [ ] **`ContinueSession` Nack(0x03 StorageHasMeasurements)**: should not occur — firmware streams live + stored automatically on `Ack`. If it does occur, log + show a generic error. Do NOT port the Android auto-recover via `StartSync` (Android `db3cebf24` / `AirBeamMiniV2Configurator.kt:755-778` is incorrect; the path is unreachable in real firmware behavior).
- [ ] **Sync confirmation dialog (start path)**: if user picks a V2 device with unsynced measurements before starting a new session, show a dialog with **Discard** (sends `DiscardSession`) or **Cancel** options. The "Sync" option will be added once firmware supports `StartSync` (Android commits `b7e2c2ca2`, `3086e1dc0`, `a586b0702`)
- [ ] **Sync confirmation dialog (finish path)**: if user finishes a V2 session and unsynced measurements remain, show the same Discard/Cancel dialog
- [ ] **Disconnected-view handling**: V2 dialog must also fire from the disconnected-view path (Android commit `3086e1dc0`)
- [ ] **Active sessions DB writes**: synced measurements must be written to the same table the live-graph reads (Android commit `a6af1ee59`)

**Done when:** Force-quit the app mid-session, relaunch, reconnect — sync chunks restore the missing window without duplicates or stale data; live data resumes; UI graph updates correctly.

**Reference Android commits:** `84050172a`, `a6af1ee59`, `eaf4c1f55`, `db3cebf24`, `7d6d15771`, `f48436cab`, `1c29a7e16`, `b7e2c2ca2`, `3086e1dc0`, `a586b0702`, `18e16b89f`, `489902d59`.

---

## Phase 4 — V2 Fixed Session (Backend + WiFi) (3–5 days)

**Goal:** Configure a fixed session through the new `/api/v3/fixed_sessions` endpoint, pass WiFi creds + session_token to the device, hand off to firmware-driven WiFi streaming.

**Tasks**
- [ ] **`V2FixedSessionAPIService`**: `POST /api/v3/fixed_sessions` with the JSON in guide §7. Use **HTTPS + port 443** (Android commits `caf2dc3b0`, `39c0a59b0`)
- [ ] **Typed Decodable** for the response (`session_token`, `streams[].sensor_type_id`, `location`) — avoid raw `Data` (Android commit `448cff1a5`)
- [ ] **`session_token` decoding**: 32-char hex string → 16 bytes → **reverse to little-endian** before BLE payload (Android commit `97bbe0f38`)
- [ ] **`NewSessionConfig (0x13)` fixed payload** (134 bytes, per guide §5.D):
  - `[0x13] + UUID_LE(16) + interval=60_LE(2) + 0x00 + pm1_idx(1) + pm25_idx(1) + token_LE(16) + ssid_padded(32) + password_padded(64)`
  - Strings null-byte padded to container length
  - **Byte 19 is the mode byte (0x00=FIXED)** — order matters (Android commit `6c6cc9b40`)
- [ ] **Interval = 60s** for fixed (Android commit `7659eeb01`)
- [ ] **NO hourly `SetTime`** for fixed — firmware gets time from `X-Server-Time` header on WiFi POSTs (Android commit `8198f4445`)
- [ ] **Configure outcome handling**:
  - `Ack` → `Ready` = success
  - `Nack(0x02 InvalidConfig)` = generic config / first-measurement POST failure → error dialog
  - `Nack(0x05 InvalidWifiCredentials)` = bad WiFi creds → dialog routing user back to WiFi entry (Android commit `8198f4445`)
- [ ] **Block "Start Recording" button** until configure returns a typed outcome (Android commits `73cf51072`, `c821f623f`)
- [ ] **Single error dialog, locked-down**: not dismissable except via OK; user can't double-start (Android commits `3708d75e4`, `bd92f041b`, `d6749096e`)
- [ ] **Keep local fixed-session row on failure**: don't delete from Core Data when configure fails — let the user retry without re-entering everything (Android commit `dd05d7989`)
- [ ] **Disconnect BLE on configure success**: device runs the fixed session over WiFi from this point; reconnect lazily for status / stop (Android commit `3708d75e4`)
- [ ] **Per-measurement `Ready` heartbeat**: while BLE is connected during a running fixed session, treat repeated `Ready` as idempotent heartbeat — do NOT re-trigger configure-success handlers (Android commit `913e1d58d`, `b266c57ab`)
- [ ] **Firmware-side resume**: on later BLE reconnect, Status may already be `Running` with a known session UUID — trust Status, do not re-configure (guide §6b, Android docs commit `157b31747`)
- [ ] **Parse fixed `end_time` as UTC** in any backend response handlers (Android commit `b21931159`)
- [ ] **DiscardSession on user-stop** (same as mobile, applies to fixed too) (Android commit `a8f4a8c15`)
- [ ] **Pre-start unsynced check**: also gate fixed-session start on the V2 unsynced-measurements dialog (Android commit `a586b0702`)

**Done when:** Configure a fixed session over a real WiFi network, unplug from app, leave overnight, see measurements in the AirCasting backend, return next day, reconnect BLE, see Status = `Running` with the correct session UUID, stop session cleanly.

**Reference Android commits:** `5b48f6159`, `b71d6416f`, `6c6cc9b40`, `7659eeb01`, `97bbe0f38`, `caf2dc3b0`, `39c0a59b0`, `448cff1a5`, `c821f623f`, `e1278dd58`, `73cf51072`, `913e1d58d`, `b266c57ab`, `3708d75e4`, `dd05d7989`, `bd92f041b`, `8198f4445`, `b21931159`, `a586b0702`, `157b31747`.

---

## Phase 5 — Polish & Hardening (1–2 days)

**Goal:** Edge-case fixes, diagnostics, parity with Android final state.

**Tasks**
- [ ] **Bluetooth on/off cycles**: ensure V2 reconnects after repeated BT toggles (Android commit `8ac3349b3`)
- [ ] **Single-disconnect events**: don't fire duplicate disconnect callbacks during connect retries (Android commit `6bef8ab73` — drop equivalent of `retry()`)
- [ ] **Defer reconnect until Status arrives**: tighten the reconnection controller (Android commit `2ae1e99fa`)
- [ ] **Live-graph fallback when no entries**: show current time as chart end-time fallback (Android commit `c071e441a`)
- [ ] **Remove diagnostic logging** from V2 measurement path before shipping (Android commits `a364aa545`, `7c920a0d0`, `3b8653217`, `3f02a0587`, `165543392`)
- [ ] **MTU verification**: confirm 244-byte sync chunks arrive intact on the lowest-supported iPhone model. iOS has no `requestMtu()` — if truncation appears, escalate to firmware to chunk smaller (Android `1c29a7e16` requested MTU 247; iOS relies on system negotiation)
- [ ] **End-to-end smoke test**: V1 Mini still works, V2 Mini mobile session start/stop/reconnect/sync works, V2 Mini fixed session works
- [ ] **Update `.claude/ble_mobile_app_guide_ios.md`** with anything learned during integration (parity with Android's "always update the guide" rule from CLAUDE.md)

**Done when:** Both V1 and V2 paths pass full QA. Guide reflects ground truth.

---

## Phase 6 — DEFERRED: Full-File `StartSync (0x12)` (post-firmware support)

**Goal:** Once firmware ships the `StartSync (0x12)` opcode, replace the V1 SD-sync flow on V2 devices and switch the unsynced-measurements dialogs from "Discard or Cancel" to "Sync, Discard, or Cancel."

**Tasks (do NOT start until firmware confirms support)**
- [ ] Wire `StartSync (0x12)` in `AirBeamMiniV2Configurator`: write opcode, await `Ack` → `SyncInfo (0x24)` (32B SSID + 64B password) → consume Sync-characteristic chunks → `Ready (0x22)` (Android `5b48f6159` for Kotlin reference)
- [ ] Replace SD-sync flow on V2 devices: `SDSyncController` is bypassed; use V2 chunks → `MeasurementsSavingService` directly
- [ ] Add **Sync** option to the unsynced-measurements confirmation dialogs (start path + finish path + disconnected view)
- [ ] Update guide §5.C and §10 to remove the "not yet implemented" caveats

(Note: do **NOT** add the Android-style `Nack(0x03) → StartSync → retry ContinueSession` auto-recovery. That Android path is incorrect — `ContinueSession` does not Nack on stored measurements; it Acks and streams both automatically.)

---

## Cross-cutting reminders

- **Backward compatibility**: V1 paths (`AirBeam3Configurator`, `HexMessagesBuilder`, `MeasurementsRecordingServices`, `BluetoothSDCardAirBeamServices`, `MiniSDCardMeasurementsParser`, `MiniSDSyncFileFactory`, `SDSyncController`, `UploadFixedSessionAPIService`) **must remain untouched**. V2 is a parallel stack.
- **Minimal changes**: do not refactor the V1 stack to "fit" V2 — branch at the DI seam (`AppDelegate+Injection.swift`), at the scan filter, and at the session-creator. Everything else is V2-only new code.
- **Always build before commit** (matches the project CLAUDE.md rule for the Android repo; same discipline for iOS — `xcodebuild` or run in Xcode before each commit).
- **Reference firmware** when in doubt: https://github.com/HabitatMap/AirbeamMiniFirmware
- **Reference Android impl** for any ambiguity: https://github.com/HabitatMap/AircastingAndroid/tree/feat/ab-integration — every commit hash in this doc lives there.
- **Update the iOS guide** (`.claude/ble_mobile_app_guide_ios.md`) whenever new V2 behavior is learned during integration — same rule as the Android guide.
