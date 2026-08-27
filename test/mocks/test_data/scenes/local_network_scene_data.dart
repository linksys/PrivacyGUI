/// Composed scenes for `usp_local_network_view` — the golden suite's six states and
/// the gate's one.
///
/// Moved here from
/// `test/golden_test/page/local_network/fixtures/local_network_test_data.dart` by
/// #1380 (wave 4), for the reason `dmz_scene_data.dart` records: the layout gate may
/// not import from `test/golden_test/` (#1361), and one fixture read by both suites
/// beats two that can disagree.
library;

import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/local_network/models/local_network_feature_state.dart';
import 'package:privacy_gui/page/local_network/models/local_network_settings.dart';
import 'package:privacy_gui/page/local_network/models/local_network_status.dart';
import 'package:privacy_gui/page/local_network/models/local_network_ui_model.dart';

const dhcpEnabledModel = LocalNetworkUIModel(
  hostName: 'LinksysRouter',
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: true,
  minAddress: '192.168.1.100',
  maxAddress: '192.168.1.200',
  leaseTimeMinutes: 1440,
  dnsServer1: '8.8.8.8',
  dnsServer2: '8.8.4.4',
  dnsServer3: '',
);

const dhcpDisabledModel = LocalNetworkUIModel(
  hostName: 'LinksysRouter',
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: false,
  minAddress: '',
  maxAddress: '',
  leaseTimeMinutes: 0,
  dnsServer1: '',
  dnsServer2: '',
  dnsServer3: '',
);

const dirtyModel = LocalNetworkUIModel(
  hostName: 'MyRouter',
  ipAddress: '192.168.2.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: true,
  minAddress: '192.168.2.100',
  maxAddress: '192.168.2.200',
  leaseTimeMinutes: 720,
  dnsServer1: '1.1.1.1',
  dnsServer2: '',
  dnsServer3: '',
);

LocalNetworkFeatureState dataState(LocalNetworkUIModel model) {
  final settings = LocalNetworkSettings(model: model);
  return LocalNetworkFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const LocalNetworkStatus(isLoading: false, lockedOctetCount: 3),
  );
}

LocalNetworkFeatureState dirtyState({bool isSaving = false}) {
  const original = LocalNetworkSettings(model: dhcpEnabledModel);
  const current = LocalNetworkSettings(model: dirtyModel);
  return LocalNetworkFeatureState(
    settings: Preservable(original: original, current: current),
    status: LocalNetworkStatus(
      isLoading: false,
      isSaving: isSaving,
      lockedOctetCount: 3,
    ),
  );
}

LocalNetworkFeatureState get errorState => LocalNetworkFeatureState(
      settings: Preservable(
        original: const LocalNetworkSettings.empty(),
        current: const LocalNetworkSettings.empty(),
      ),
      status: const LocalNetworkStatus(
        isLoading: false,
        error: ConnectivityError(detail: 'Connection failed'),
      ),
    );

LocalNetworkFeatureState get validationErrorState {
  const settings = LocalNetworkSettings(model: dhcpEnabledModel);
  return LocalNetworkFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const LocalNetworkStatus(
      isLoading: false,
      lockedOctetCount: 3,
      validationErrors: {
        'ipAddress': 'Invalid IP address',
        'minAddress': 'Start address must be within subnet range',
      },
    ),
  );
}

LocalNetworkFeatureState validationErrorAllState() {
  const model = LocalNetworkUIModel(
    hostName: '',
    ipAddress: '999.999.999.999',
    subnetMask: '0.0.0.0',
    dhcpEnabled: true,
    minAddress: '10.0.0.1',
    maxAddress: '10.0.0.1',
    leaseTimeMinutes: 0,
    dnsServer1: '999.999.999.999',
    dnsServer2: '999.999.999.999',
    dnsServer3: '999.999.999.999',
  );
  const settings = LocalNetworkSettings(model: model);
  return LocalNetworkFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const LocalNetworkStatus(
      isLoading: false,
      lockedOctetCount: 3,
      validationErrors: {
        'hostName': 'Hostname is required',
        'ipAddress': 'Invalid IP address',
        'subnetMask': 'Invalid subnet mask',
        'minAddress': 'Not in same subnet as router',
        'maxAddress': 'Must be after pool start',
        'leaseTime': 'Must be 1–525600 minutes',
        'dnsServer1': 'Invalid DNS address',
        'dnsServer2': 'Invalid DNS address',
        'dnsServer3': 'Invalid DNS address',
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// The gate scene
// ---------------------------------------------------------------------------

/// The router shape every `page.local_network` cell is measured against.
///
/// [dhcpEnabledModel] with the third DNS server filled in. `dhcpEnabled` is the whole
/// reason: `_buildDhcpCard` renders the header row alone when the server is off, and
/// four more [LayoutBlock]s when it is on — the address pool, the three DNS fields,
/// and the reservations link row. Sweeping [dhcpDisabledModel] would measure a page
/// missing two thirds of its widgets, including the one row on this page whose shape
/// has failed three times elsewhere in this wave (a `spaceBetween` label beside an
/// inflexible trailing child, here `viewDhcpReservations` beside a chevron).
///
/// `dnsServer3` is filled where the golden model leaves it empty. An empty
/// [AppIpv4TextField] is the same box as a full one, so this is not about width — it
/// is that a router with three resolvers is as ordinary as one with two, and the
/// golden state that leaves it blank is the only one either suite has.
///
/// Not `dirtyState()`: the save bar is here either way. Unlike the rest of this
/// family, `_buildBottomBar` returns a config unconditionally — the comment there
/// says why (a null bar changes the tree shape and unfocuses text fields on Flutter
/// Web) — so a clean scene renders the same bar with its buttons disabled, and the
/// scene that adds nothing is the one to sweep. Overflow *inside* the bar is ui_kit's
/// own and out of scope for #1380 either way.
final gateLocalNetworkState = dataState(_gateModel);

const _gateModel = LocalNetworkUIModel(
  hostName: 'LinksysRouter',
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: true,
  minAddress: '192.168.1.100',
  maxAddress: '192.168.1.200',
  leaseTimeMinutes: 1440,
  dnsServer1: '8.8.8.8',
  dnsServer2: '8.8.4.4',
  dnsServer3: '1.1.1.1',
);
