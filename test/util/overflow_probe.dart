/// The gate's measurement spine, now a re-export of `test/layout_gate/`.
///
/// Everything this file used to define lives under `test/layout_gate/` and is
/// re-exported from here, so its ~22 importers are untouched — every symbol they
/// reach for still resolves through `import '.../overflow_probe.dart'`:
///
/// | symbol | now defined in |
/// |---|---|
/// | [OverflowIncident], [kOverflowTolerancePx], [isOverflowError], [normalizeOverflowSourcePath] | `../layout_gate/incident.dart` (#1338) |
/// | [normalizeOverflowDumpPaths], [stripOverflowObjectIds] | the same file, since #1339 folded the golden framework's parser into it |
/// | [runWithOverflowCollection], [collectOverflow], [settleIgnoringAnimations] | `../layout_gate/collector.dart` (#1340) |
/// | [setLayoutSurface] | `../layout_gate/surface.dart` (#1340) |
///
/// The move is complete: this file is a shim and nothing else. Relocating a test
/// utility with that many callers would mean touching ~70 files for no
/// behavioural gain, so the framework layer is additive and the old paths
/// re-export from it (`doc/testing/overflow_gate_architecture.md` §3.1).
///
/// New code inside the gate family should import the `test/layout_gate/` file it
/// actually needs; this path exists for the callers that predate the framework,
/// and for `overflow_probe_test.dart`, which imports it *because* it is the shim —
/// every symbol that test uses doubles as proof the old path still resolves.
library;

export '../layout_gate/collector.dart';
export '../layout_gate/incident.dart';
export '../layout_gate/surface.dart';
