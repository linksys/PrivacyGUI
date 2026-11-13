/// Composed scenes for `usp_ddns_view` (#641) — what the layout gate pumps.
///
/// The gate's scene is the page at its fullest: a provider chosen, so the three
/// fields render; every field showing its error, so each error line is laid out
/// under its field; the password field's "leave blank to keep" hint, which only a
/// stored account shows; and beside it a status card on a connection failure
/// behind a private WAN address, the one status that adds a note under the rows.
/// No real save produces all three field errors at once with an account stored —
/// the scene is a layout premise, not a moment in a flow.
library;

import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/ddns/models/ddns_feature_state.dart';
import 'package:privacy_gui/page/ddns/models/ddns_rules.dart';
import 'package:privacy_gui/page/ddns/models/ddns_status.dart';
import 'package:privacy_gui/page/ddns/models/ddns_update_status.dart';

import '../ddns_test_data.dart';

/// No-IP chosen, an account and a host name stored, the password untouched,
/// and every field shown as failing.
final gateDdnsState = DdnsFeatureState(
  settings: Preservable(
    original: DdnsTestData.configuredSettings(),
    current: DdnsTestData.configuredSettings(),
  ),
  status: const DdnsStatus(
    isLoading: false,
    fieldErrors: {DdnsField.username, DdnsField.password, DdnsField.hostname},
  ),
);

/// The status that draws the most: Failed, with the private-address note under
/// it when the WAN address is private (the gate's WAN is `100.64.0.10`).
const gateDdnsUpdateStatus = DdnsUpdateStatus.connectionFailed;
