# Airbeam Mini V2 — iOS Implementation Phases

Phased plan for porting V2 firmware support to `HabitatMap/AirCastingiOS`. Each phase is shippable in isolation and leaves V1 fully intact. Phase boundaries mirror the Android rollout (commits reachable from `origin/dev`) so Android source can be referenced 1:1 while implementing.

Always read `.claude/ble_mobile_app_guide_ios.md` alongside this file — it has the protocol details. This file is the **work breakdown**.

**Reference repos:**
- Android implementation: https://github.com/HabitatMap/AircastingAndroid/tree/dev (all commit hashes below are fetchable from this branch)
- Firmware: https://github.com/HabitatMap/AirbeamMiniFirmware

**Status (May 2026):** BLE manual sync via `StartBleSync (0x16)` has shipped on firmware and Android. Phase 6 below now covers implementing it on iOS — it is no longer deferred. The legacy WiFi-SoftAP `StartWiFiSync (0x12)` path is dormant on Android; **skip it entirely on iOS**.

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

**Status: shipped in iOS.** Phases 1 + 2 are also shipped (confirmed via the iOS-side handoff that produced this guide).

---

## Phase 1 — V2 BLE Connection Infrastructure (2–3 days) — **SHIPPED**

**Goal:** Detect a V2 device, connect, subscribe to all 5 characteristics, decode Status, decode battery. No commands sent yet.

**Tasks**
- [x] **Scan-time detection**: in `BluetoothManager.swift` `centralManager(_:didDiscover:advertisementData:rssi:)`, read `advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]` and stamp `firmwareVersion = .v2` on the discovered `BluetoothDevice` if it contains `a0e1f000-0001-...`
- [x] **Connection-time confirmation**: re-stamp `firmwareVersion = .v2` after `peripheral(_:didDiscoverServices:)` confirms the V2 service. Persist on the `Device` Core Data entity (Android commit `bf0325243`)
- [x] **GATT discovery in `AirBeamMiniV2Configurator`**: discover service `a0e1f000-0001-...`; discover all 5 characteristics; verify all present (fail connection otherwise)
- [x] **Subscribe** to Status, Response, Measurement, Sync via `setNotifyValue(true, for:)`
- [x] **300ms settle delay** before any command (`DispatchQueue.main.asyncAfter`)
- [x] **Status decoder** in `V2BinaryProtocol.swift`:
  - `0x00` Idle → `(battery, isCharging)`
  - `0x01` HasSavedSession → `(battery, isCharging, sessionUUID, hasMeasurements, fileSize)` — **27-byte payload** (was 19; FW commit `3990cf22`)
  - `0x02` Running → `(battery, isCharging, sessionUUID)` (18 bytes; no `hasMeasurements`)
  - `0x03` ReadyToSync → `(fileSize, password_bytes)` — **no battery byte at offset 1**; parser must short-circuit (FW commit `ed751b180`)
- [x] **Battery decoder**: `Int8(bitPattern: byte)`; `abs()` is %; sign is charging direction (skip for `0x03`)
- [x] **UUID LE helpers**: `UUID.toLEBytes()` and `UUID.fromLEBytes(_:)` (see guide §5)
- [x] **Status fallback read**: if no Status notification arrives within 1s of subscription, explicitly `readValue(for: statusCharacteristic)` (Android commit `9ec55ffb2`)
- [x] **Reconnection plumbing**: ensure `ReconnectionController.swift` defers any V2 action until the first Status notification arrives (Android commit `2ae1e99fa`)
- [ ] **Optional**: read GATT Firmware Revision String (`0x2A26`) and log for diagnostics (Android commit `974a12652`)

**Done when:** Plug in a V2 device, connect, observe correct Status state and battery % (incl. charging sign) in the UI / logs. No session can be started yet.

**Reference Android commits:** `f63f3abf3`, `bf0325243`, `9ec55ffb2`, `ab84c44f6`, `2ae1e99fa`, `8ac3349b3`, `6bef8ab73`, `974a12652`.

---

## Phase 2 — V2 Mobile Session: Configure + Live Streaming (3–4 days) — **SHIPPED**

**Goal:** Start a mobile session on a V2 device and stream live measurements directly to Core Data.

**Tasks**
- [x] **Command writer** in `AirBeamMiniV2Configurator`: write opcode bytes via `peripheral.writeValue(_:for: commandChar, type: .withResponse)`
- [x] **Response dispatcher** (`V2ResponseDispatcher.swift`):
  - First byte switch: `0x20 Ack`, `0x21 Nack(errorCode)`, `0x22 Ready`, `0x23 SensorInfo`, `0x24 SyncInfo`
  - Per-pending-command completion handlers; clear on terminal response
  - **Idempotent Ready**: track which `Ready` is "first" (completes setup) vs subsequent (heartbeat); only the first fires the user-visible callback (Android commit `913e1d58d`, `b266c57ab`)
- [x] **`GetSensors (0x14)`** on connect → store `"PM1,μg/m3;PM2.5,μg/m3"` for stream metadata
- [x] **`SetTime (0x15)`** on connect (immediate) and on a 1-hour `Timer` (mobile sessions only)
- [x] **`DiscardSession (0x11)`** on Status = `HasSavedSession` before starting a new session (Android commit `ac5925900`)
- [x] **`NewSessionConfig (0x13)` mobile payload** (build per guide §5.D):
  - `[0x13] + UUID_LE(16) + interval_LE(2) + 0x01` = 20 bytes total, NO session_token
  - Wait for `Ack` then `Ready` before signalling success
- [x] **Live measurement parser** (`V2MeasurementParser.swift`): decode 9-byte indication
- [x] **Direct DB save**: write to `MeasurementsSavingService` directly (V2 owns its writes); do NOT go through V1's measurement-observer pipeline for V2 mobile sessions (Android commit `18e16b89f`)
- [x] **UI refresh notification**: post a `NotificationCenter` event so live-graph and active controllers refresh (Android commit `3d69a19c3`)
- [x] **`DiscardSession` on stop**: when the user finishes the session, write `0x11` and **wait for `Ready`** before disconnecting (Android commits `a8f4a8c15`, `1b89ba35d`)
- [x] **Error dialog**: surface `Nack` errors via a single `UIAlertController` (Android commits `884cbd24b`, `d6749096e`, `bd92f041b`)
- [x] **Off-by-one fix**: when wiring V2 sensors into the live-graph presenter, double-check `indexOf` arithmetic (Android commit `d35b566e6` crashed on first measurement here)

**Done when:** Start a V2 mobile session, watch live PM1 / PM2.5 values stream, stop the session, verify the device returns to Idle on next connection.

**Reference Android commits:** `cd666ed21`, `884cbd24b`, `d35b566e6`, `913e1d58d`, `b266c57ab`, `d9a29f896`, `a862f1583`, `a8f4a8c15`, `1b89ba35d`, `ac5925900`, `8198f4445`, `3d69a19c3`, `18e16b89f`, `d6749096e`, `bd92f041b`.

---

## Phase 3 — V2 Mobile Session Reconnection + Active Sync (2–3 days) — **SHIPPED**

**Goal:** Handle BLE reconnection mid-session; consume the firmware's auto-stream of stored chunks on the Sync characteristic.

**Tasks**
- [x] **Sync chunk parser**: 244-byte indication → `[count_u8, padding_2B, record_0(8B), ...]`; each record = `[ts_u32_LE, pm1_u16_LE, pm25_u16_LE]` — `V2MeasurementParser.parseSyncChunk`
- [x] **Per-chunk DB save**: write each chunk's records to Core Data immediately (do not accumulate) — `AirBeamMiniV2Configurator.persistSyncChunkLocked` calls `MeasurementsSavingService.saveV2SyncMeasurement` per record
- [x] **Session UUID validation**: compare `savedSessionUuid` (decoded from last Status via `UUID.fromLEBytes`) to current app session UUID; if mismatch → **discard the chunk**. `persistSyncChunkLocked` reads `lastStatus?.sessionUUID` and bails on mismatch. Android commits `18e16b89f`, `489902d59`
- [x] **Scenario A — Status `Running` on reconnect**: passive; chunks + live measurements stream automatically. `resumeSessionAfterReconnect.case .running` just sets `mobileSessionActive = true` + `scheduleHourlySetTime`; subscriptions already re-armed by `prepareForReconnect`.
- [x] **Scenario B — Status `HasSavedSession` on reconnect**: send `ContinueSession (0x10)`. `resumeSessionAfterReconnect.case .hasSavedSession` → `sendContinueSession` (awaitAckThenReady).
- [x] **`ContinueSession` Nack(0x03 StorageHasMeasurements)**: dispatcher maps to `DispatchError.nack(.storageHasMeasurements, ...)`, propagated through `sendContinueSession` completion. No auto-recover via `StartSync` (Android `db3cebf24` deliberately skipped).
- [x] **Active-sync drain detection**: `isActiveSyncDrainingStorage` flag on the configurator, set on every Sync indication via `bumpActiveSyncDrainingLocked`; reset 3 s after the last chunk via `syncDrainResetWorkItem`. Exposed via `isActiveSyncDraining: Bool` accessor and posted on `NotificationCenter.v2SyncDrainChanged` (`AirCastingNotificationKeys.V2SyncDrainChanged.{deviceUUID, isDraining}`). Android commit `daf8cef01`.
- [x] **Don't drop synced rows that predate latest live row**: `persistSyncChunkLocked` writes every parsed record without any timestamp filter. Dedupe happens at the Core Data layer via the unique constraint below. Android commit `a76d43451`.
- [x] **Unique index on `(session, stream, time)`**: Core Data **v10** model adds `uniquenessConstraints` on `MeasurementEntity` for `(measurementStream, time)` (stream→session is 1:1, so equivalent). All contexts in `PersistenceController` now use `NSMergeByPropertyStoreTrumpMergePolicy` so the existing live row wins on a sync replay collision. Android commit `357d4002c`.
- [x] **Active sessions DB writes**: `saveV2SyncMeasurement` routes through `MeasurementsSavingService.updateStreams` — same `addMeasurementValue` path the live-graph observer reads. Android commit `a6af1ee59`.

**Extra hardening shipped during Phase 3 integration** (Phase 7 / 8 territory, pulled forward because real-device testing surfaced them):

- [x] **Reconnect retry loop** in `DefaultReconnectionController`: 10 s connect timeout, 3 s delay between attempts, 40-attempt cap (~8.5 min). Power-cycle reboot exceeds a single 10 s timeout, so a single-shot reconnect always failed; the loop runs through the reboot window. Logs tagged `[RECONNECT]`.
- [x] **`AirBeamMiniV2Configurator.prepareForReconnect()`**: wipes `subscriptionTokens`, `lastStatus`, drain timer, and dispatcher session-start guard before re-subscribing. CoreBluetooth invalidates per-peripheral subscriptions across a disconnect; without the wipe `ensureSubscriptions()` no-ops on reconnect (tokens still in array) and `subscribeAndAwaitStatus` returns a stale cached status.
- [x] **`SetTime` on reconnect**: pushed before the Scenario A/B branch so post-power-cycle live indications carry a 2026 wall-clock instead of the firmware's boot-counter range (was producing `1970-01-01` timestamps that fell outside the session's chart window).
- [x] **DISCONNECTED status flip during retry**: new `didStartReconnecting` delegate method on `ReconnectionControllerDelegate`; `SessionManagingReconnectionController` flips the active session to `.DISCONNECTED` on the first disconnect and back to `.RECORDING` via `changeStatusToRecording` on successful resume. Card surfaces the "Disconnected" affordance while the retry loop runs.
- [x] **Reconnect chain dedupe** via `activeReconnects: Set<String>`: CoreBluetooth emits two `didDisconnectPeripheral` events when a connect attempt times out (real disconnect + cleanup disconnect), each spawning a chain that thrashed `deviceBusy` against the other. Dedup ensures one chain per device UUID.
- [x] **Synthetic disconnect on `.poweredOff` / `.resetting`** in `BluetoothManager`: track `trackedConnectedPeripherals` and fire `didDisconnect` on observers when central goes down. CoreBluetooth doesn't fire `didDisconnectPeripheral` on a phone-side BT toggle, so the auto-retry chain wouldn't kick in.
- [x] **Open live-measurement gate at resume entry**: `mobileSessionActive = true` is set at the top of `resumeSessionAfterReconnect`, not after `ContinueSession Ready`. Real firmware can lag `Ready` ~12 s behind `Ack`; live indications arriving in that window were dropped by the `guard mobileSessionActive` check.
- [x] **Manual Reconnect button** on `StandaloneSessionCardView` (reusing `ReconnectSessionCardViewModel`). Branch A (active session matches device) calls the new `ReconnectionController.kickReconnectNow(for:)`, which skips the current retry sleep and triggers the next `attemptReconnect` immediately — no parallel BLE connect from the manual path. Branch B (post-exhaustion, no active session) still scans+connects via the original `UserTriggeredReconnectionController` flow and flips status via `changeStatusToRecording`.

**Done when:** Force-quit the app mid-session, relaunch, reconnect — sync chunks restore the missing window without duplicates or stale data; live data resumes; UI graph updates correctly.

**Reference Android commits:** `84050172a`, `a6af1ee59`, `eaf4c1f55`, `db3cebf24`, `7d6d15771`, `f48436cab`, `1c29a7e16`, `18e16b89f`, `489902d59`, `daf8cef01`, `a76d43451`, `357d4002c`.

**iOS commits:** `b7f65fe8` (core Phase 3), `494b0adb` (retry loop), `38fe8852` (chain dedupe + DISCONNECTED flip + live gate), `b26453f0` (SetTime on reconnect), `a71cfc82` (BT-toggle synthetic disconnect), `7670f8b9` / `4e366e53` / `b292a975` / `214a9ba5` / `7027eb02` (manual Reconnect button + UI state).

---

## Phase 4 — V2 Fixed Session (Backend + WiFi) (3–5 days) — **CORE SHIPPED**

**Goal:** Configure a fixed session through the new `/api/v3/fixed_sessions` endpoint, pass WiFi creds + session_token to the device, hand off to firmware-driven WiFi streaming.

**Tasks**
- [x] **`V2FixedSessionAPIService`**: `POST /api/v3/fixed_sessions` — `AirCasting/APICommunicator/V2/V2FixedSessionAPIService.swift`. Uses `URLProvider.baseAppURL` so backend host is centralised (the default just moved to `experimental.aircasting.org`).
- [x] **Typed Decodable** for the response (`session_token`, `streams[].sensor_type_id`, `location`) — `V2FixedSessionAPI.Response`.
- [x] **`session_token` decoding**: 32-char hex string → 16 bytes → **reverse to little-endian** before BLE payload — `V2BinaryProtocol.sessionTokenBytesLE(fromHex:)`.
- [x] **`NewSessionConfig (0x13)` fixed payload** (134 bytes) — `V2BinaryProtocol.buildNewSessionConfigFixed(uuid:pm1Index:pm25Index:sessionTokenHex:wifiSSID:wifiPassword:)`. Mode byte fixed at 0x00 at offset 19.
- [x] **Interval = 60s** hard-coded for fixed — `V2BinaryProtocol.fixedIntervalSeconds`. No UI input on fixed-session screen.
- [x] **NO hourly `SetTime`** for fixed — `scheduleHourlySetTime()` is only called from the mobile session entry paths.
- [x] **Configure outcome handling**: `awaitAckThenReady` resolves on `Ready`; `Nack(0x02)` / `Nack(0x05)` propagate through `DispatchError` with localized descriptions.
- [x] **Keep local fixed-session row on failure** — `AirBeamFixedWifiSessionCreator.createV2Session` persists the row after the V3 POST succeeds and leaves it in place if `configureV2FixedSession` later fails.
- [x] **Disconnect BLE on configure success** — `AirBeamFixedWifiSessionCreator` calls `BluetoothConnectionHandler.disconnect(from:)` + `V2ConfiguratorRegistry.release` after `Ready`.
- [x] **Per-measurement `Ready` heartbeat** — already covered by `V2ResponseDispatcher.firstReadyConsumed` (Phase 2).
- [x] **Firmware-side resume**: on BLE reconnect to a fixed-session device, `AirBeamMiniV2Configurator.subscribeAndAwaitStatus` returns `Running` with the saved UUID; the recording controller trusts Status and does not re-configure.
- [x] **Parse fixed `end_time` as UTC for indoor sessions** — `Date.shiftedForFixedSession(isIndoor:)` (`AirCasting/Extensions/Date+Extensions.swift`); applied in `UpdateSessionParamsService` and `DownloadMeasurementsService` external-session path. `FixedSession.FixedMeasurementOutput.is_indoor` was added to the response model so the indicator threads end-to-end.

**Done when:** Configure a fixed session over a real WiFi network, unplug from app, leave overnight, see measurements in the AirCasting backend, return next day, reconnect BLE, see Status = `Running` with the correct session UUID, stop session cleanly. Indoor session timestamps match real wall-clock time on the dashboard.

**Reference Android commits:** `5b48f6159`, `b71d6416f`, `6c6cc9b40`, `7659eeb01`, `97bbe0f38`, `caf2dc3b0`, `39c0a59b0`, `448cff1a5`, `c821f623f`, `e1278dd58`, `73cf51072`, `913e1d58d`, `b266c57ab`, `3708d75e4`, `dd05d7989`, `bd92f041b`, `8198f4445`, `b21931159`, `157b31747`, `47c19f0aa`, `4e3ee96c4`, `0d148625c`, `338c2b1f1`, `9999289ce`, `ffc79d2bf`, `fa52f77f0`, `f1fe732d4`.

---

## Phase 5 — User-Configurable Mobile Interval + Sparse-Interval Averaging (1–2 days)

**Goal:** Let the user pick a mobile-session sample interval (≥ 1s) without breaking AirCasting's averaging logic.

**Background:** Averaging assumes the native sample rate is finer than the averaging window. A 5s-native session in the FIRST(5s) window — or any session with native ≥ window — has ≤ 1 sample per window; the averaging pass then wipes the rows via its leftover-sweep. Result: session card stays, but `measurements` is empty (graph/map/share/upload fail silently).

**Tasks**
- [ ] **UI**: add an "Interval (seconds)" integer input on the **mobile** new-session-details screen; default 1, accept ≥ 1. **Do not add this control on the fixed-session screen** (interval is hard-coded 60s — Android commit `47c19f0aa`).
- [ ] **Plumbing**: thread `intervalSeconds: Int?` from the session-details screen → the iOS session-creator pipeline → `AirBeamMiniV2Configurator.sendNewSessionConfig` → mobile payload builder. Default to 1s when the param is null (legacy/non-V2 paths). Android commit `02d0baeba`.
- [ ] **Core Data migration**: add `measurementInterval: Int16?` to the `Session` entity (lightweight migration). Persist the native interval per session on insert (V2 sessions only; V1/external rows stay `nil` and are interpreted as 1s native).
- [ ] **Averaging gate**: in whatever the iOS equivalent of `AveragingService` is, skip averaging for any window where `nativeInterval >= window.value`:
  - 1s session → averages at FIRST(5s) and SECOND(60s).
  - 5s session → skips FIRST(5s), runs SECOND(60s).
  - ≥60s session → skips both; do not schedule periodic averaging at all.
    Also apply the same per-tick gate to the periodic (live) averaging path so a 5s live session doesn't write a misleading `averagingFrequency=5` before crossing 9 h.
- [ ] **If iOS has no equivalent averaging logic**: leave the column in place for future use; just guard any future averaging scheduler on the same rule.

**Done when:** Start mobile sessions at 1s, 5s, 10s, 60s, and 600s — the session card always shows measurements; graph populates; share/upload work end-to-end.

**Reference Android commits:** `02d0baeba`, `c4cdd9b9a`, `47c19f0aa`.

---

## Phase 6 — V2 BLE Manual Sync (`StartBleSync 0x16`) + Drain-Aware Finish (3–5 days)

**Goal:** Replace the V1 SD-sync flow on V2 devices with a BLE-only manual sync, and gate session-finish on draining stored measurements. Also gate new-session-start on syncing any pre-existing stored measurements.

**This used to be the "deferred Phase 6" — firmware has now shipped `StartBleSync 0x16` and Android has it in production. iOS should implement it now.**

**Tasks**
- [ ] **New opcode constant** `OPCODE_START_BLE_SYNC = 0x16` and **new Nack code** `NACK_SYNC_FAILED = 0x06` in `V2BinaryProtocol.swift`
- [ ] **`V2BleSyncOrchestrator.swift`**:
  - Writes `0x16` to the Command characteristic; expects `Ack (0x20)`.
  - Routes Sync-characteristic indications through a **registered manual-sync handler** while a manual sync is in flight (bypasses the default reconnect-time DB save path so mobile vs fixed routing is correct).
  - Observes `ReadyToSync (Status 0x03)` **in parallel** (subscribe before writing `0x16`) to pick up `file_size` ~100 ms after the write — do **not** `await` it from a serial chain after the post-stream `Ready 0x22` (by then every chunk has already arrived with `expectedSize == 0` and progress stays at 0%).
  - Computes progress per chunk: `receivedBytes += 5 + 8 × chunk.count`; `pct = receivedBytes × 100 / file_size`; clamp 0..99 mid-stream; set to 100 on `Ready 0x22`.
  - Settles on `Ready (0x22)` (success), `Nack (0x06 SyncFailed)` (failure — records remain on device for retry), or `Nack (0x04 ClearStorageFailed)` (post-stream wipe failed).
  - **No app-side `DiscardSession`** on success — firmware auto-clears storage in its Stop handler.
- [ ] **Sync confirmation dialog (start path) — `SyncBeforeNewV2SessionDialog.swift`**:
  - Fires when the user picks a V2 device in `HasSavedSession` to start a new session.
  - Three buttons: **Sync** (drives `StartBleSync`), **Discard** (drives `DiscardSession`), **Cancel**.
  - Use `file_size` from the Status payload for the ETA hint via `estimateSyncSeconds(fileSize)` (calibrate `BYTES_PER_SECOND` constant on iOS empirically; Android uses ~1700).
  - On post-sync success, **keep the BLE link open** and proceed straight to `NewSessionConfig` — do not bounce (Android commit `83abfb408`).
  - Drive the actual sync from inside the dialog (Android commit `7e4115d0b`).
- [ ] **Sync confirmation dialog (finish path) — `SyncAndFinishV2SessionDialog.swift`**:
  - Show the standard `FinishSessionConfirmationDialog` first to confirm intent.
  - **Re-evaluate `hasSavedMeasurements || isActiveSyncDraining` at confirm time, not at button-tap time** (Android commit `991f6f6e4`).
  - If true at confirm, present the sync-and-finish dialog (chained, not replacing). Non-cancelable; auto-start `StartBleSync (0x16)` on open (Android commit `2425b0be3`) so `ReadyToSync (0x03)` lands with `file_size` and gives a fresh ETA even when the user opened it from a `Running` Status that lacked the suffix.
  - Show progress percent during the stream.
  - **"Discard & Finish"** cancels the orchestrator's job mid-stream; firmware honors `DiscardSession (0x11)` even while `StartBleSync` is in flight, wiping on-device storage. Records collected so far are NOT inserted into the DB on this branch.
  - On success: insert records, mark session FINISHED in local DB, push to backend on confirm (Android commit `87fe4fa39`).
  - On failure (`Nack 0x06`): show error; on confirm, post the equivalent of `StopRecordingEvent` — the trailing `0x11` write wipes on-device data.
- [ ] **Disconnected-view path**: fires the same sync-and-finish dialog from the disconnected-session view (Android commit `3086e1dc0`).
- [ ] **ETA UI polish**: bold the ETA hint, format with localized "min." / "sec.", line-break the description (Android commits `cdc938108`, `340e677c9`, `c798a9921`, `376f91c81`).
- [ ] **SD-sync wizard "Unplug AirBeam" screen**: skip entirely on V2; reorder to AFTER the "successfully synced" screen on V1 (Android commit `dcef0b695`).
- [ ] **Drain idle-timeout constant**: 3 s (`SYNC_DRAIN_IDLE_TIMEOUT_MS`).

**Done when:** Start a mobile session, accumulate stored measurements (force-quit + relaunch), then tap Finish — the sync-and-finish dialog appears, streams the backlog to the DB, then completes the session and pushes to backend. Discard mid-stream wipes the device cleanly. Starting a new session with a stored backlog offers Sync / Discard / Cancel and uses the ETA from `HasSavedSession.file_size`.

**Reference Android commits:** `975ca4c9b`, `c91f5bb4a`, `19e2e4b05`, `28ea5d5ae`, `c356f630d`, `0b23711fa`, `cdc938108`, `340e677c9`, `376f91c81`, `daf8cef01`, `886058649`, `3526b79f8`, `2ab5f4377`, `2425b0be3`, `991f6f6e4`, `7e05a35e8`, `c798a9921`, `87fe4fa39`, `7e4115d0b`, `83abfb408`, `f1fe732d4`, `dcef0b695`, `a586b0702`, `b7e2c2ca2`, `3086e1dc0`.

---

## Phase 7 — V2 → V1 Fallback + Reconnection Hardening (1–2 days)

**Goal:** Edge cases around mixed-firmware fleets, repeated reconnects, and stale state-flow observers. Skip portions that don't apply to CoreBluetooth.

**Tasks**
- [ ] **Don't tear down session state on "V2 service not supported"**: if a V1 device is reached via the V2 attempt path, the `peripheral(_:didDiscoverServices:)` will return without the V2 service — handle this as a **fallback transition**, not a true disconnect. Do NOT post the unexpected-disconnect notification or stop the recording service before the V1 attempt. (Android Nordic equivalent: commits `9033d2640`, `62ddc827a`, `484cd11e4`.)
- [ ] **Capture V2/V1 leg at closure creation**: if iOS queues a V2 attempt then a V1 attempt, any failure-callback closure on the V2 attempt must close over `let isV2Leg = true` at queue time — do not read a mutable "current attempt" property at callback time (Android commit `67656474d`, `f38cb2089`).
- [ ] **Per-leg idempotent failure callbacks**: guard against duplicate V2-failure / V1-failure callbacks (Android commit `9b6dbd044`).
- [ ] **Explicit V2 state reset** between fallback attempts: clear the V2 configurator's characteristics, pending commands, and observable state before the V1 attempt starts (Android commit `484cd11e4`).
- [ ] **Reconnection loop**: no hard cap on attempts; surface "still reconnecting…" UI rather than a permanent failure (Android commit `c31e1797e`).
- [ ] **Route `.fail` to connection-failed path, not disconnect path**: disconnect handlers tear down state the next attempt needs (Android commit `b838eb4f6`).
- [ ] **Cancel previous observer subscriptions on each reconnect**: when the V2 configurator is recreated, cancel previous Combine subscriptions / async tasks so the new instance owns the stream (Android commits `57154f2df`, `17f6182bb`, `8e6ade2fc`).
- [ ] **Use `Task.sleep` / `DispatchQueue` delay between retries**, not a blocking sleep (Android commit `2b9502e1e`).
- [ ] **Finalize with an error when retries exhaust** (Android commit `ca5988b35`).
- [ ] **`[RECONNECT]` log tags** across the reconnection path (Android commit `b8787fbc6`).

> If iOS doesn't support mixed V1/V2 in a single session-creation flow, the V2→V1 fallback bullets can be deferred. The reconnection-hardening bullets apply regardless.

**Reference Android commits:** `9033d2640`, `62ddc827a`, `484cd11e4`, `9b6dbd044`, `67656474d`, `f38cb2089`, `c31e1797e`, `b838eb4f6`, `b8787fbc6`, `57154f2df`, `ca5988b35`, `2b9502e1e`, `17f6182bb`, `8e6ade2fc`.

---

## Phase 8 — Polish & Hardening (1–2 days)

**Goal:** Edge-case fixes, diagnostics, parity with Android final state.

**Tasks**
- [ ] **Bluetooth on/off cycles**: ensure V2 reconnects after repeated BT toggles (Android commit `8ac3349b3`)
- [ ] **Single-disconnect events**: don't fire duplicate disconnect callbacks during connect retries (Android commit `6bef8ab73`)
- [ ] **Defer reconnect until Status arrives**: tighten the reconnection controller (Android commit `2ae1e99fa`)
- [ ] **Live-graph fallback when no entries**: show current time as chart end-time fallback (Android commit `c071e441a`)
- [ ] **Remove diagnostic logging** from V2 measurement path before shipping (Android commits `a364aa545`, `7c920a0d0`, `3b8653217`, `3f02a0587`, `165543392`)
- [ ] **MTU verification**: confirm 244-byte sync chunks arrive intact on the lowest-supported iPhone model. iOS has no `requestMtu()` — if truncation appears, escalate to firmware to chunk smaller (Android `1c29a7e16` requested MTU 247; iOS relies on system negotiation).
- [ ] **End-to-end smoke test**: V1 Mini still works, V2 Mini mobile session start/stop/reconnect/sync works, V2 Mini fixed session works (indoor + outdoor), drain-aware finish works, sync-before-new-session works, mobile interval picker works.
- [ ] **Update `.claude/ble_mobile_app_guide_ios.md`** with anything learned during integration (parity with Android's "always update the guide" rule from CLAUDE.md).

**Done when:** Both V1 and V2 paths pass full QA. Guide reflects ground truth.

---

## Cross-cutting reminders

- **Backward compatibility**: V1 paths (`AirBeam3Configurator`, `HexMessagesBuilder`, `MeasurementsRecordingServices`, `BluetoothSDCardAirBeamServices`, `MiniSDCardMeasurementsParser`, `MiniSDSyncFileFactory`, `SDSyncController`, `UploadFixedSessionAPIService`) **must remain untouched**. V2 is a parallel stack.
- **Minimal changes**: do not refactor the V1 stack to "fit" V2 — branch at the DI seam (`AppDelegate+Injection.swift`), at the scan filter, and at the session-creator. Everything else is V2-only new code.
- **Skip the legacy WiFi-SoftAP manual sync path entirely on iOS.** Android keeps `V2SyncOrchestrator` / `V2WifiApConnector` / `V2SyncFileDownloader` as dormant code; iOS should not implement them at all. Manual sync is BLE-only via `StartBleSync (0x16)`.
- **Always build before commit** (matches the project CLAUDE.md rule for the Android repo; same discipline for iOS — `xcodebuild` or run in Xcode before each commit).
- **Reference firmware** when in doubt: https://github.com/HabitatMap/AirbeamMiniFirmware
- **Reference Android impl** for any ambiguity: https://github.com/HabitatMap/AircastingAndroid/tree/dev — every commit hash in this doc is reachable from that branch (verified May 2026).
- **Update the iOS guide** (`.claude/ble_mobile_app_guide_ios.md`) whenever new V2 behavior is learned during integration — same rule as the Android guide.
