/// What a disruptive router operation destroys — the parameter of cause 4's
/// second member, `ProximityStrategy.canRecoverFrom`.
///
/// **Classified by consequence, not by name.** "Factory reset" and "reboot" are
/// both destructive-sounding operations that take the box down for a minute, and
/// the reason one is refused in Remote Assistance and the other is not has
/// nothing to do with how alarming they sound: a reset wipes the admin
/// credential Guardian is proxying, and a reboot does not. Naming the
/// consequence is what lets a mode answer once for a whole family of operations
/// instead of maintaining a list of operation names — which is the shape #1474
/// rejected after phase 8 deleted three per-mode capability flags with zero
/// consumers each.
///
/// The set is deliberately small. There are three answers a mode has to give,
/// and they are given per *cause of loss*; a fourth value is only justified by a
/// measured case where some mode answers it differently from all three below.
///
/// See `doc/mode_strategy/mode_strategy_guide.md` and constitution Article XVII.
/// Rule 3: a contract's parameter types live beside the contract in
/// `lib/framework/mode/`, the same reason `RecoveryPlan` and `BridgeConfig` do.
enum DisruptionClass {
  /// The operation destroys the credential the mode authenticates with.
  ///
  /// Factory reset. Locally that is recoverable by definition — the reset put
  /// the password back to the one printed on the sticker, and the operator can
  /// read the sticker. Remotely there is no sticker and no second channel: the
  /// Guardian session is proxying an admin login that has just stopped existing,
  /// so the agent watches a probe loop that can never succeed and the router is
  /// left in setup mode with nobody able to reach it.
  credentialLoss,

  /// The operation needs a byte path to the router that this mode does not have
  /// separately from the session's own.
  ///
  /// Local firmware upload. **Manual firmware update is a local-only feature** —
  /// a product decision, confirmed 2026-09-08, and the reason this value exists
  /// rather than the arithmetic below.
  ///
  /// That ordering matters, because the *technical* argument for the same refusal
  /// was drafted first and was wrong. Phase 6 originally asserted that the upload
  /// is aimed at Guardian under Remote Assistance and therefore simply broken.
  /// It is not. `firmware_local_upload_service.dart:26` does read
  /// `window.location`, but that value feeds exactly one line —
  /// `wsUrl: 'wss://$routerHost/usp-ws'`, the Method-2 WebSocket accelerator. The
  /// default and always-available Method 1, `FirmwareHttpUploadStrategy`, holds
  /// nothing but a `UspClient` and pushes through
  /// `FirmwareOperations.chunkedPush`, i.e. over the same mode-aware transport a
  /// reboot and a cloud OTA already use, and `uploadFile` falls back to it
  /// automatically when the WebSocket `prepare()` throws, which under RA it does.
  /// The upload **would work** remotely. It is refused because the feature is not
  /// offered there, not because the bytes have nowhere to go.
  ///
  /// What the cost measurement is still good for is explaining *why* the product
  /// constraint is the right one, i.e. why nobody should be tempted to un-refuse
  /// it: remotely the only working path is the session's own control channel, and
  /// the upload monopolises it. A 70 MB image at
  /// `FirmwareChunker.defaultChunkBytes` (65,535) is **1,121 sequential USP
  /// Operate round trips**, each carrying ~87 KB of base64 across browser →
  /// Guardian → agent → router, each taking `UspMutationLock`, awaited one at a
  /// time. Locally that loop runs over a LAN socket the accelerator can bypass
  /// entirely. Cloud OTA is the remote answer for the same need, and the router
  /// fetches over its own uplink.
  ///
  /// **One consequence worth recording, because it retires a suspected defect.**
  /// The Method-2 `wss://` host is derived from `window.location`, which would be
  /// Guardian's host under RA — filed as a defect while the refusal was still
  /// being justified technically. With the feature local-only, that code is
  /// unreachable in the only mode where the host would be wrong, and in local
  /// mode `window.location.host` *is* the router. It is not a defect. The one
  /// that survives is unrelated to mode: a push abandoned partway leaves a
  /// partial image in the router's target bank, locally included.
  transportLoss,

  /// The operation takes the box, or its radios, away and they come back on
  /// their own — with the credential and the path intact.
  ///
  /// Reboot, cloud OTA upgrade, triggering an install of an image the router
  /// already holds, and a Wi-Fi settings change. Every mode allows all of these
  /// today, and the two proximity strategies agree on this value: it is the
  /// class whose whole content is "nothing is lost".
  ///
  /// **`transientRestart`, not #1496's `transientReboot`.** The ticket's third
  /// value was named for a reboot, and then its own operation table listed a
  /// Wi-Fi change, which restarts the radios and never the box. Keeping the
  /// narrower name would have meant either classifying a Wi-Fi change as a
  /// reboot — a value that lies about what happens, on the one operation where
  /// the two modes' *recovery* answers already differ — or inventing a fourth
  /// value that both modes answer identically. `RecoveryTrigger` already draws
  /// the reboot/radios distinction where it matters, in
  /// `ProximityStrategy.planFor`.
  transientRestart,
}
