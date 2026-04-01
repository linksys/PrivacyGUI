import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/models/firewall_settings.dart';
import 'package:privacy_gui/page/firewall/models/firewall_status.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';
import 'package:privacy_gui/page/firewall/views/usp_firewall_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

const _allOnModel = FirewallUIModel(
  isIPv4FirewallEnabled: true,
  isIPv6FirewallEnabled: true,
  blockIPSec: false,
  blockPPTP: false,
  blockL2TP: false,
  blockAnonymousRequests: true,
  blockMulticast: true,
  blockIDENT: false,
);

const _allOffModel = FirewallUIModel(
  isIPv4FirewallEnabled: false,
  isIPv6FirewallEnabled: false,
  blockIPSec: true,
  blockPPTP: true,
  blockL2TP: true,
  blockAnonymousRequests: false,
  blockMulticast: false,
  blockIDENT: false,
);

/// Dirty model: differs from _allOnModel by toggling IPv6 off.
const _dirtyCurrentModel = FirewallUIModel(
  isIPv4FirewallEnabled: true,
  isIPv6FirewallEnabled: false, // changed from true
  blockIPSec: false,
  blockPPTP: false,
  blockL2TP: false,
  blockAnonymousRequests: true,
  blockMulticast: true,
  blockIDENT: false,
);

FirewallFeatureState _dataState(FirewallUIModel model) {
  final settings = FirewallSettings(
    model: model,
    ruleContext: FirewallRuleContext.empty,
  );
  return FirewallFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const FirewallStatus(isLoading: false),
  );
}

FirewallFeatureState _dirtyState({bool isSaving = false}) {
  final original = FirewallSettings(
    model: _allOnModel,
    ruleContext: FirewallRuleContext.empty,
  );
  final current = FirewallSettings(
    model: _dirtyCurrentModel,
    ruleContext: FirewallRuleContext.empty,
  );
  return FirewallFeatureState(
    settings: Preservable(original: original, current: current),
    status: FirewallStatus(isLoading: false, isSaving: isSaving),
  );
}

// ---------------------------------------------------------------------------
// Golden tests
// ---------------------------------------------------------------------------

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewId: 'FWALL',
      view: () => const UspFirewallView(),
      shell: ShellType.custom, // View already wraps in UiKitPageView
      states: {
        // Required states
        'loading': (mock) => mock.firewall(FirewallFeatureState.initial()),
        'error': (mock) => mock.firewall(
              FirewallFeatureState(
                settings: Preservable(
                  original: FirewallSettings.empty(),
                  current: FirewallSettings.empty(),
                ),
                status: const FirewallStatus(
                  isLoading: false,
                  errorMessage: 'Connection failed',
                ),
              ),
            ),
        'data': (mock) => mock.firewall(_dataState(_allOnModel)),

        // Additional states
        'data_all_off': (mock) => mock.firewall(_dataState(_allOffModel)),
        'edit_dirty': (mock) => mock.firewall(_dirtyState()),
        'saving': (mock) => mock.firewall(_dirtyState(isSaving: true)),
      },
    ),
  );
}
