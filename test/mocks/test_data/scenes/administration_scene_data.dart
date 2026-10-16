/// Composed states for `usp_administration_view` — Advanced Settings →
/// Administration (#1660). Not `admin_scene_data.dart`, which is the menu's
/// password / time zone / reboot page.
library;

import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/administration/models/administration_feature_state.dart';
import 'package:privacy_gui/page/administration/models/administration_settings.dart';
import 'package:privacy_gui/page/administration/models/administration_status.dart';

/// UPnP on, SIP ALG off, nothing edited: the shipping defaults, and what the
/// gate sweeps.
final upnpOnState = AdministrationFeatureState(
  settings: Preservable(
    original:
        const AdministrationSettings(upnpEnabled: true, sipAlgEnabled: false),
    current:
        const AdministrationSettings(upnpEnabled: true, sipAlgEnabled: false),
  ),
  status: const AdministrationStatus(),
);
