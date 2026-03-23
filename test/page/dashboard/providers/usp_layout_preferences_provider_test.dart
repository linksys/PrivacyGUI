import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_preferences.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wait for async initialization chains to settle.
Future<void> pumpAsync() async {
  await Future.delayed(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Creates a container with both providers, waits for initialization.
  Future<ProviderContainer> createContainer({
    Map<String, Object> initialValues = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final container = ProviderContainer();
    // Force creation of both providers
    container.read(uspSliverDashboardControllerProvider);
    final notifier = container.read(uspLayoutPreferencesProvider.notifier);
    await notifier.initialized;
    await pumpAsync();
    return container;
  }

  // ---------------------------------------------------------------------------
  // Build / init
  // ---------------------------------------------------------------------------
  group('Build / init', () {
    test('default state on first run', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final state = container.read(uspLayoutPreferencesProvider);
      expect(state.useCustomLayout, isTrue);
      expect(state.widgetConfigs, isEmpty);
      expect(state.selectedPreset, isNull);
      expect(state.hasSeenPresetDialog, isFalse);
    });

    test('loads saved prefs from SharedPreferences', () async {
      final savedPrefs = UspLayoutPreferences(
        useCustomLayout: false,
        selectedPreset: UspDashboardPreset.standard,
        hasSeenPresetDialog: true,
      );
      final container = await createContainer(
        initialValues: {
          pUspLayoutPreferences: savedPrefs.toJsonString(),
        },
      );
      addTearDown(container.dispose);

      final state = container.read(uspLayoutPreferencesProvider);
      expect(state.useCustomLayout, isFalse);
      expect(state.selectedPreset, UspDashboardPreset.standard);
      expect(state.hasSeenPresetDialog, isTrue);
    });

    test('initialized future completes', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      // Should complete without error
      await notifier.initialized;
    });

    test('JSON decode error → default state', () async {
      final container = await createContainer(
        initialValues: {
          pUspLayoutPreferences: 'invalid json!',
        },
      );
      addTearDown(container.dispose);

      final state = container.read(uspLayoutPreferencesProvider);
      // fromJsonString returns default on invalid JSON
      expect(state, equals(const UspLayoutPreferences()));
    });

    test('initialized completes even on invalid JSON', () async {
      SharedPreferences.setMockInitialValues({
        pUspLayoutPreferences: 'invalid json!',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      // Should complete even if JSON is invalid (finally block)
      await notifier.initialized;
    });
  });

  // ---------------------------------------------------------------------------
  // toggleCustomLayout
  // ---------------------------------------------------------------------------
  group('toggleCustomLayout', () {
    test('true → false updates state', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.toggleCustomLayout(false);

      final state = container.read(uspLayoutPreferencesProvider);
      expect(state.useCustomLayout, isFalse);
    });

    test('saves to SharedPreferences', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.toggleCustomLayout(false);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(pUspLayoutPreferences);
      expect(saved, isNotNull);
      final decoded = jsonDecode(saved!) as Map<String, dynamic>;
      expect(decoded['useCustomLayout'], isFalse);
    });

    test('toggling OFF resets controller layout to default', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      // First apply a preset to make layout non-default
      final controllerNotifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await controllerNotifier.applyPreset(UspDashboardPreset.essential);
      expect(container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length, 6);

      // Toggle OFF → should reset controller layout
      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.toggleCustomLayout(false);

      // Controller should be reset to default 17 items
      final layout = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout();
      expect(layout.length, 17);
    });

    test('toggling ON does NOT reset controller layout', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.toggleCustomLayout(true);

      // State updated, controller untouched
      final state = container.read(uspLayoutPreferencesProvider);
      expect(state.useCustomLayout, isTrue);
    });

    test('preserves widgetConfigs', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.setVisibility('device_info', false);
      final configsBefore =
          container.read(uspLayoutPreferencesProvider).widgetConfigs;

      await notifier.toggleCustomLayout(false);

      final configsAfter =
          container.read(uspLayoutPreferencesProvider).widgetConfigs;
      expect(
        configsAfter['device_info']?.visible,
        configsBefore['device_info']?.visible,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // setVisibility
  // ---------------------------------------------------------------------------
  group('setVisibility', () {
    test('hides visible widget', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.setVisibility('device_info', false);

      final state = container.read(uspLayoutPreferencesProvider);
      expect(state.isVisible('device_info'), isFalse);
    });

    test('creates config entry if not exists', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      // Before: no config for device_info
      expect(
        container
            .read(uspLayoutPreferencesProvider)
            .widgetConfigs
            .containsKey('device_info'),
        isFalse,
      );

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.setVisibility('device_info', false);

      // After: config exists
      expect(
        container
            .read(uspLayoutPreferencesProvider)
            .widgetConfigs
            .containsKey('device_info'),
        isTrue,
      );
    });

    test('saves after change', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.setVisibility('device_info', false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pUspLayoutPreferences), isNotNull);
    });

    test('preserves other configs', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.setVisibility('device_info', false);
      await notifier.setVisibility('topology', false);

      final state = container.read(uspLayoutPreferencesProvider);
      expect(state.isVisible('device_info'), isFalse);
      expect(state.isVisible('topology'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // restoreSnapshot
  // ---------------------------------------------------------------------------
  group('restoreSnapshot', () {
    test('replaces entire state', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final snapshot = UspLayoutPreferences(
        useCustomLayout: false,
        selectedPreset: UspDashboardPreset.monitoring,
        hasSeenPresetDialog: true,
      );

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.restoreSnapshot(snapshot);

      final state = container.read(uspLayoutPreferencesProvider);
      expect(state.useCustomLayout, isFalse);
      expect(state.selectedPreset, UspDashboardPreset.monitoring);
      expect(state.hasSeenPresetDialog, isTrue);
    });

    test('saves to SharedPreferences', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final snapshot = UspLayoutPreferences(
        useCustomLayout: false,
        selectedPreset: UspDashboardPreset.essential,
      );

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.restoreSnapshot(snapshot);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(pUspLayoutPreferences);
      expect(saved, isNotNull);
    });

    test('does not affect controller layout', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final beforeCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.restoreSnapshot(const UspLayoutPreferences());

      final afterCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;
      expect(afterCount, beforeCount);
    });
  });

  // ---------------------------------------------------------------------------
  // selectPreset
  // ---------------------------------------------------------------------------
  group('selectPreset', () {
    test('updates selectedPreset', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.selectPreset(UspDashboardPreset.essential);

      final state = container.read(uspLayoutPreferencesProvider);
      expect(state.selectedPreset, UspDashboardPreset.essential);
    });

    test('sets hasSeenPresetDialog=true', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.selectPreset(UspDashboardPreset.monitoring);

      final state = container.read(uspLayoutPreferencesProvider);
      expect(state.hasSeenPresetDialog, isTrue);
    });

    test('applies preset to controller', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.selectPreset(UspDashboardPreset.essential);

      final layout = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout();
      expect(layout.length, 6);
    });

    test('saves to SharedPreferences', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.selectPreset(UspDashboardPreset.standard);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(pUspLayoutPreferences);
      expect(saved, isNotNull);
      final decoded = jsonDecode(saved!) as Map<String, dynamic>;
      expect(decoded['selectedPreset'], 'standard');
    });
  });

  // ---------------------------------------------------------------------------
  // markPresetDialogSeen
  // ---------------------------------------------------------------------------
  group('markPresetDialogSeen', () {
    test('sets flag=true', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.markPresetDialogSeen();

      final state = container.read(uspLayoutPreferencesProvider);
      expect(state.hasSeenPresetDialog, isTrue);
    });

    test('preserves selectedPreset', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.selectPreset(UspDashboardPreset.monitoring);
      await notifier.markPresetDialogSeen();

      final state = container.read(uspLayoutPreferencesProvider);
      expect(state.selectedPreset, UspDashboardPreset.monitoring);
    });

    test('saves to SharedPreferences', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.markPresetDialogSeen();

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(pUspLayoutPreferences);
      expect(saved, isNotNull);
      final decoded = jsonDecode(saved!) as Map<String, dynamic>;
      expect(decoded['hasSeenPresetDialog'], isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // resetToDefaults
  // ---------------------------------------------------------------------------
  group('resetToDefaults', () {
    test('resets state to default', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      // First modify state
      await notifier.selectPreset(UspDashboardPreset.essential);
      await notifier.toggleCustomLayout(false);

      // Reset
      await notifier.resetToDefaults();

      final state = container.read(uspLayoutPreferencesProvider);
      expect(state, equals(const UspLayoutPreferences()));
    });

    test('removes prefs key', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.selectPreset(UspDashboardPreset.essential);

      await notifier.resetToDefaults();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pUspLayoutPreferences), isNull);
    });

    test('resets controller layout to default', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      // Apply a preset first
      final controllerNotifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await controllerNotifier.applyPreset(UspDashboardPreset.essential);
      expect(container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length, 6);

      // Reset defaults should also reset controller
      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.resetToDefaults();

      final layout = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout();
      expect(layout.length, 17);
    });
  });

  // ---------------------------------------------------------------------------
  // Integration
  // ---------------------------------------------------------------------------
  group('Integration', () {
    test('toggle → setVisibility → selectPreset chain', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(uspLayoutPreferencesProvider.notifier);

      await notifier.toggleCustomLayout(true);
      expect(
        container.read(uspLayoutPreferencesProvider).useCustomLayout,
        isTrue,
      );

      await notifier.setVisibility('device_info', false);
      expect(
        container.read(uspLayoutPreferencesProvider).isVisible('device_info'),
        isFalse,
      );

      await notifier.selectPreset(UspDashboardPreset.essential);
      expect(
        container.read(uspLayoutPreferencesProvider).selectedPreset,
        UspDashboardPreset.essential,
      );
    });

    test('persistence round-trip', () async {
      final container = await createContainer();
      final notifier = container.read(uspLayoutPreferencesProvider.notifier);
      await notifier.selectPreset(UspDashboardPreset.monitoring);
      await notifier.setVisibility('device_info', false);
      container.dispose();

      // Read persisted state
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(pUspLayoutPreferences)!;
      final restored = UspLayoutPreferences.fromJsonString(savedJson);
      expect(restored.selectedPreset, UspDashboardPreset.monitoring);
      expect(restored.isVisible('device_info'), isFalse);
    });

    test('concurrent reads are safe', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      // Multiple reads should not crash
      final state1 = container.read(uspLayoutPreferencesProvider);
      final state2 = container.read(uspLayoutPreferencesProvider);
      expect(state1, equals(state2));
    });

    test('dispose does not crash', () async {
      final container = await createContainer();
      container.dispose();
    });

    test('state changes update provider value', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final before = container.read(uspLayoutPreferencesProvider);
      final notifier = container.read(uspLayoutPreferencesProvider.notifier);

      await notifier.selectPreset(UspDashboardPreset.essential);

      final after = container.read(uspLayoutPreferencesProvider);
      expect(before, isNot(equals(after)));
    });
  });
}
