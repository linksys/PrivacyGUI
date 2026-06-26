import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/models/firewall_settings.dart';
import 'package:privacy_gui/page/firewall/models/firewall_status.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';

const allOnModel = FirewallUIModel(
  isIPv4FirewallEnabled: true,
  isIPv6FirewallEnabled: true,
  blockIPSec: false,
  blockPPTP: false,
  blockL2TP: false,
  blockAnonymousRequests: true,
  blockMulticast: true,
  blockIDENT: false,
);

const allOffModel = FirewallUIModel(
  isIPv4FirewallEnabled: false,
  isIPv6FirewallEnabled: false,
  blockIPSec: true,
  blockPPTP: true,
  blockL2TP: true,
  blockAnonymousRequests: false,
  blockMulticast: false,
  blockIDENT: false,
);

const dirtyCurrentModel = FirewallUIModel(
  isIPv4FirewallEnabled: true,
  isIPv6FirewallEnabled: false,
  blockIPSec: false,
  blockPPTP: false,
  blockL2TP: false,
  blockAnonymousRequests: true,
  blockMulticast: true,
  blockIDENT: false,
);

FirewallFeatureState dataState(FirewallUIModel model) {
  final settings = FirewallSettings(
    model: model,
    ruleContext: FirewallRuleContext.empty,
  );
  return FirewallFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const FirewallStatus(isLoading: false),
  );
}

FirewallFeatureState dirtyState({bool isSaving = false}) {
  final original = FirewallSettings(
    model: allOnModel,
    ruleContext: FirewallRuleContext.empty,
  );
  final current = FirewallSettings(
    model: dirtyCurrentModel,
    ruleContext: FirewallRuleContext.empty,
  );
  return FirewallFeatureState(
    settings: Preservable(original: original, current: current),
    status: FirewallStatus(isLoading: false, isSaving: isSaving),
  );
}

FirewallFeatureState get errorState => FirewallFeatureState(
      settings: Preservable(
        original: FirewallSettings.empty(),
        current: FirewallSettings.empty(),
      ),
      status: const FirewallStatus(
        isLoading: false,
        error: ConnectivityError(detail: 'Connection failed'),
      ),
    );
