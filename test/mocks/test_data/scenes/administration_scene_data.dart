/// Composed states for `usp_administration_view` — Advanced Settings →
/// Administration (#1660). Not `admin_scene_data.dart`, which is the menu's
/// password / time zone / reboot page.
library;

import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/administration/models/administration_feature_state.dart';
import 'package:privacy_gui/page/administration/models/administration_settings.dart';
import 'package:privacy_gui/page/administration/models/administration_status.dart';

/// UPnP on, SIP ALG off, management over Wi-Fi on, nothing edited: the
/// shipping defaults on a firmware with RULE_MGMT_WIFI_ACCESS, and what the
/// gate sweeps — every card the page can show.
final upnpOnState = AdministrationFeatureState(
  settings: Preservable(
    original: const AdministrationSettings(
        upnpEnabled: true, sipAlgEnabled: false, mgmtWifiEnabled: true),
    current: const AdministrationSettings(
        upnpEnabled: true, sipAlgEnabled: false, mgmtWifiEnabled: true),
  ),
  status: const AdministrationStatus(),
);
