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

DmzFeatureState get errorState => DmzFeatureState(
      settings: Preservable(
        original: DmzSettings.empty(),
        current: DmzSettings.empty(),
      ),
      status: const DmzStatus(
        isLoading: false,
        errorMessage: 'Connection failed',
      ),
    );
