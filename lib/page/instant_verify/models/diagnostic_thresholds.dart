/// Cutoffs that Instant Test and the Instant AI engine both apply to the same
/// evidence. Each one must equal the `decided` boundary in the shared table,
/// linksys/linksys-ai-msdm `docs/contracts/thresholds.v0.json`; a vendored
/// copy lives in `test/page/instant_verify/contracts/` and
/// `diagnostic_thresholds_conformance_test.dart` checks every predicate below
/// against it at its boundary.
///
/// Change a value here only together with that table, in one reviewed change
/// on each side (linksys/linksys-ai-msdm#699, Stage 0 seam 2).
///
/// Display tiers (signal labels, badges, backhaul health colours) are not
/// shared findings and are not defined here.
library;

/// `wifi.client_signal.weak`: a client at or below -75 dBm has a weak signal.
const int kClientSignalWeakAtDbm = -75;

/// `wifi.client_signal.strong`: a client at or above -65 dBm is strong.
const int kClientSignalStrongAtDbm = -65;

/// `mesh.backhaul.weak`: wireless backhaul at or below -75 dBm is weak.
const int kBackhaulWeakAtDbm = -75;

/// `router.uptime.restart_hint`: suggest a restart after more than 30 days.
const int kUptimeRestartHintAfterDays = 30;

/// `system.memory.high`: memory use above 85% is high.
const int kMemoryHighAbovePct = 85;

/// `internet.latency.high`: latency above 100 ms is high.
const int kLatencyHighAboveMs = 100;

bool isWeakClientSignal(int dBm) => dBm <= kClientSignalWeakAtDbm;

bool isStrongClientSignal(int dBm) => dBm >= kClientSignalStrongAtDbm;

bool isWeakBackhaulSignal(int dBm) => dBm <= kBackhaulWeakAtDbm;

bool uptimeSuggestsRestart(int days) => days > kUptimeRestartHintAfterDays;

bool isMemoryHigh(int pct) => pct > kMemoryHighAbovePct;

bool isLatencyHigh(int ms) => ms > kLatencyHighAboveMs;
