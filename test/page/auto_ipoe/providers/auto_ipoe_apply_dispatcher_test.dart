import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_apply_dispatcher.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_internet_settings_bridge.dart';

/// The bridge, recording which of its saves each screen reached and with what.
class _RecordingBridge extends Fake implements AutoIPoEInternetSettingsBridge {
  final calls = <String, Map<String, Object?>>{};

  @override
  Future<void> saveIPoEInternetSettings({
    required AutoIPoESettings settings,
    required WanType? originalWanType,
    AutoIPoEStatus? originalStatus,
  }) async {
    calls['saveIPoEInternetSettings'] = {
      'settings': settings,
      'originalWanType': originalWanType,
      'originalStatus': originalStatus,
    };
  }

  @override
  Future<void> savePnpIPoE({AutoIPoESettings? settings}) async {
    calls['savePnpIPoE'] = {'settings': settings};
  }

  @override
  Future<void> resetIfNeededBeforeSaving({
    required WanType? originalWanType,
    AutoIPoEStatus? originalStatus,
  }) async {
    calls['resetIfNeededBeforeSaving'] = {
      'originalWanType': originalWanType,
      'originalStatus': originalStatus,
    };
  }
}

void main() {
  late _RecordingBridge bridge;
  late ProviderContainer container;

  AutoIPoEApplyDispatcher dispatcher() =>
      container.read(autoIPoEApplyDispatcherProvider);

  // Not the defaults, so a dispatcher that passed a default instead of what it
  // was given would not match; and not const, so the match cannot rest on one
  // canonical instance.
  final settings =
      AutoIPoESettings(isEnabled: true, selectedMode: AutoIPoEMode.auto);
  final status = AutoIPoEStatus.fromMap(
      const {'isEnabled': true, 'isCurrentWANType': true, 'mode': 'Auto'});

  setUp(() {
    bridge = _RecordingBridge();
    container = ProviderContainer(overrides: [
      autoIPoEInternetSettingsBridgeProvider.overrideWithValue(bridge),
    ]);
  });

  tearDown(() => container.dispose());

  test('Internet Settings applies through the save that knows the old WAN type',
      () async {
    await dispatcher().applyFromInternetSettings(
      settings: settings,
      originalWanType: WanType.pppoe,
      originalStatus: status,
    );

    expect(bridge.calls, {
      'saveIPoEInternetSettings': {
        'settings': settings,
        'originalWanType': WanType.pppoe,
        'originalStatus': status,
      },
    });
  });

  test('PnP applies through its own save, with no old WAN type', () async {
    await dispatcher().applyFromPnp(settings: settings);

    expect(bridge.calls, {
      'savePnpIPoE': {'settings': settings},
    });
  });

  test('leaving IPoE asks the bridge to reset what the old WAN type needs',
      () async {
    await dispatcher().resetBeforeLeavingIPoE(
      originalWanType: WanType.ipoe,
      originalStatus: status,
    );

    expect(bridge.calls, {
      'resetIfNeededBeforeSaving': {
        'originalWanType': WanType.ipoe,
        'originalStatus': status,
      },
    });
  });
}
