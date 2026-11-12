import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/ddns/models/ddns_feature_state.dart';
import 'package:privacy_gui/page/ddns/models/ddns_settings.dart';
import 'package:privacy_gui/page/ddns/models/ddns_status.dart';

import '../../../mocks/test_data/ddns_test_data.dart';

DdnsFeatureState _state({
  required DdnsSettings original,
  DdnsSettings? current,
  DdnsStatus status = const DdnsStatus(isLoading: false),
}) =>
    DdnsFeatureState(
      settings: Preservable(original: original, current: current ?? original),
      status: status,
    );

void main() {
  group('DdnsFeatureState - initial', () {
    test('is loading with empty settings', () {
      final state = DdnsFeatureState.initial();

      expect(state.status.isLoading, isTrue);
      expect(state.settings.current, const DdnsSettings.empty());
      expect(state.isDirty, isFalse);
    });
  });

  group('DdnsFeatureState - canSave', () {
    test('nothing changed: no', () {
      expect(
          _state(original: DdnsTestData.configuredSettings()).canSave, isFalse);
    });

    test('a valid change: yes', () {
      final original = DdnsTestData.configuredSettings();

      expect(
        _state(
          original: original,
          current: original.copyWith(hostname: 'other.example.net'),
        ).canSave,
        isTrue,
      );
    });

    test('a change that fails a check: no, before any field loses focus', () {
      final original = DdnsTestData.configuredSettings();

      final state = _state(
        original: original,
        current: original.copyWith(hostname: 'bad_name'),
      );

      expect(state.status.fieldErrors, isEmpty);
      expect(state.canSave, isFalse);
    });

    test('choosing "Disabled" over a stored account: yes', () {
      final original = DdnsTestData.configuredSettings();

      expect(
        _state(
          original: original,
          current: original.copyWith(clearProviderPath: true),
        ).canSave,
        isTrue,
      );
    });

    test('while a save runs: no', () {
      final original = DdnsTestData.configuredSettings();

      expect(
        _state(
          original: original,
          current: original.copyWith(password: 'secret'),
          status: const DdnsStatus(isLoading: false, isSaving: true),
        ).canSave,
        isFalse,
      );
    });
  });

  group('DdnsFeatureState - copyWith', () {
    test('replaces the status and keeps the settings', () {
      final state = _state(original: DdnsTestData.configuredSettings());

      final next = state.copyWith(
          status: const DdnsStatus(isLoading: false, isSaving: true));

      expect(next.status.isSaving, isTrue);
      expect(next.settings, state.settings);
    });
  });

  group('DdnsFeatureState - toMap', () {
    test('carries nothing: the page persists no state', () {
      expect(DdnsFeatureState.initial().toMap(), isEmpty);
    });
  });
}
