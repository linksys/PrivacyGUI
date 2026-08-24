/// The two viewports the golden suite and the non-golden widget tests agree on.
///
/// They lived on `GoldenDevice` in `test/golden_test/golden_framework/`, and
/// `test/page/dhcp/views/components/dhcp_card_test_harness.dart` reached into the
/// golden suite for one of them — a whole framework import for a `Size`, and the
/// last non-fixture reason a page test named `test/golden_test/` at all (#1361).
///
/// Declared here rather than duplicated because the agreement is the point: the DHCP
/// card tests assert single-line layout at "mobile", and what makes that assertion
/// mean anything is that it is the same mobile the golden baselines were shot at. Two
/// copies of `Size(480, 800)` agree until one of them is edited.
///
/// Same shape as `test/util/app_test_fonts.dart`, which
/// `test/golden_test/flutter_test_config.dart` imports for the same reason: a neutral
/// util outside both suites, so neither depends on the other.
///
/// The gate's own widths are *not* here. `dashboard_card_probe.dart` enumerates every
/// screen width from `kMinSupportedScreenWidth` to `kMaxScannedScreenWidth` and picks
/// each span's narrowest realization, so it has no viewport list to share — and
/// putting these two in front of it would invite exactly the sampled scan #1225
/// retired.
library;

import 'package:flutter/painting.dart';

/// Mobile: the narrow end of the two, and the one the DHCP card tests measure.
///
/// 480×800 rather than a real handset's logical size — it is the golden suite's
/// long-standing choice and the baselines are shot at it, so it is a coordinate
/// rather than a claim about a device.
const Size kPhoneViewportSize = Size(480, 800);

/// Desktop: the wide end. Same height, so a golden pair differs in width only.
const Size kDesktopViewportSize = Size(1280, 800);
