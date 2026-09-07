/// Composed scenes for `usp_dmz_view` — the golden suite's four states and the
/// gate's one.
///
/// Moved here from `test/golden_test/page/dmz/fixtures/dmz_test_data.dart` (#1380,
/// wave 4) for the reason #1361 moved dhcp's: the layout gate may not import from
/// `test/golden_test/`, and a second copy of these six factories would be a fixture
/// the two suites could disagree about. The golden suite reads the same names from
/// here now, so `page.dmz` and the four localization goldens are fed by one file.
library;

import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/dmz/models/dmz_feature_state.dart';
import 'package:privacy_gui/page/dmz/models/dmz_settings.dart';
import 'package:privacy_gui/page/dmz/models/dmz_status.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';

// ---------------------------------------------------------------------------
// UI Models
// ---------------------------------------------------------------------------

const disabledModel = DmzUIModel.disabled();

const enabledAnyModel = DmzUIModel(
  isEnabled: true,
  destIp: '192.168.1.100',
  sourceType: DmzSourceType.any,
  sourcePrefix: '',
);

const enabledCidrModel = DmzUIModel(
  isEnabled: true,
  destIp: '192.168.1.100',
  sourceType: DmzSourceType.cidr,
  sourcePrefix: '10.0.0.0/24',
);

const dirtyCurrentModel = DmzUIModel(
  isEnabled: true,
  destIp: '192.168.1.200',
  sourceType: DmzSourceType.any,
  sourcePrefix: '',
);

// ---------------------------------------------------------------------------
// State factories
// ---------------------------------------------------------------------------

DmzFeatureState dataState(DmzUIModel model, {String? instancePath}) {
  final settings = DmzSettings(
    model: model,
    instancePath: instancePath,
  );
  return DmzFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const DmzStatus(isLoading: false),
  );
}

DmzFeatureState dirtyState({bool isSaving = false}) {
  final original = DmzSettings(
    model: enabledAnyModel,
    instancePath: 'Device.Firewall.DMZ.1.',
  );
  final current = DmzSettings(
    model: dirtyCurrentModel,
    instancePath: 'Device.Firewall.DMZ.1.',
  );
  return DmzFeatureState(
    settings: Preservable(original: original, current: current),
    status: DmzStatus(isLoading: false, isSaving: isSaving),
  );
}

// ---------------------------------------------------------------------------
// The gate scene
// ---------------------------------------------------------------------------

/// The router shape every `page.dmz` cell is measured against.
///
/// [enabledCidrModel] rather than [enabledAnyModel] or [disabledModel], and the
/// choice is the whole fixture: `_buildContent` renders the destination and source
/// cards only `if (pending.isEnabled)`, and the source card's CIDR field is an
/// `expandedWidget` that exists only while `sourceType == cidr`. Disabled is one
/// card and a paragraph; `any` is three cards with the third's field absent. This
/// is the only state in which all three cards and every field are on screen, which
/// is what 234 cells should be spent on.
///
/// `instancePath` is set because the page's own geometry does not read it but its
/// bottom bar's enablement does: with a path the state is a clean edit of an
/// existing entry, so `isDirty` is false and the `save`/`cancel` pair renders
/// disabled. A dirty scene would measure the same page with two live buttons —
/// worth a cell if the bar were this page's risk, and it is not: the bar is
/// `UiKitBottomBarConfig`, ui_kit's own, and out of scope per #1380.
final gateDmzState = dataState(
  enabledCidrModel,
  instancePath: 'Device.Firewall.DMZ.1.',
);
