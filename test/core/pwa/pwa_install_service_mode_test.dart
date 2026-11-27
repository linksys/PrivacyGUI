// PwaInstallService on the web: which install banner it shows (its PwaMode),
// on any router model (#1975).
//
// The service runs on the Dart VM through its seam: isWeb is true, and
// _FakePwaLogic stands in for the browser. On the VM, PwaLogic and
// BeforeInstallPromptEvent are the stubs in pwa_logic_stub.dart, so this file
// runs on the VM only.
@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/pwa/pwa_install_service.dart';
import 'package:privacy_gui/core/pwa/pwa_logic.dart';
import 'package:privacy_gui/providers/global_model_number_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A router that is not a DU model: before #1975, only DU models offered PWA.
const _notDuModel = 'LN16-EU';

/// The browser, as PwaInstallService sees it through PwaLogic.
class _FakePwaLogic extends Fake implements PwaLogic {
  _FakePwaLogic({
    this.earlyEvent,
    this.isIOS = false,
    this.isMacSafari = false,
    this.isStandalone = false,
  });

  /// The `beforeinstallprompt` that web/early-bootstrap.js captured before the
  /// app started. initListeners replays it, as the browser's PwaLogic does.
  final BeforeInstallPromptEvent? earlyEvent;

  @override
  final bool isIOS;
  @override
  final bool isMacSafari;
  @override
  final bool isStandalone;

  Function(BeforeInstallPromptEvent)? _onBeforeInstallPrompt;
  VoidCallback? _onAppInstalled;

  /// The events the service asked the browser to show its install prompt for.
  final prompted = <BeforeInstallPromptEvent>[];

  bool get isListening => _onBeforeInstallPrompt != null;

  @override
  void initListeners({
    required Function(BeforeInstallPromptEvent) onBeforeInstallPrompt,
    required VoidCallback onAppInstalled,
  }) {
    _onBeforeInstallPrompt = onBeforeInstallPrompt;
    _onAppInstalled = onAppInstalled;
    final early = earlyEvent;
    if (early != null) onBeforeInstallPrompt(early);
  }

  @override
  Future<void> prompt(BeforeInstallPromptEvent event) async {
    prompted.add(event);
  }

  /// The browser fires `beforeinstallprompt`.
  void offerInstall(BeforeInstallPromptEvent event) =>
      _onBeforeInstallPrompt!(event);

  /// The browser fires `appinstalled`.
  void appInstalled() => _onAppInstalled!();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Starts the service as the app does. [modelNumber] '' is the app before it
  /// has read the router's device info.
  ProviderContainer start(
    _FakePwaLogic browser, {
    bool isWeb = true,
    String modelNumber = '',
  }) {
    final container = ProviderContainer(overrides: [
      globalModelNumberProvider.overrideWith((ref) => modelNumber),
      pwaInstallServiceProvider.overrideWith(
          () => PwaInstallService(logic: browser, isWeb: isWeb)),
    ]);
    addTearDown(container.dispose);
    container.read(pwaInstallServiceProvider);
    return container;
  }

  PwaMode modeOf(ProviderContainer container) =>
      container.read(pwaInstallServiceProvider);

  group('the browser offers its install prompt', () {
    test('shows the native banner on a router that is not a DU model',
        () async {
      final browser = _FakePwaLogic();
      final container = start(browser, modelNumber: _notDuModel);
      await pumpEventQueue();

      browser.offerInstall(BeforeInstallPromptEvent());
      await pumpEventQueue();

      expect(modeOf(container), PwaMode.native);
    });

    test(
        'shows the native banner for a prompt captured before the app '
        'started, and keeps it once the router\'s model is read', () async {
      final browser = _FakePwaLogic(earlyEvent: BeforeInstallPromptEvent());
      final container = start(browser);
      await pumpEventQueue();

      expect(modeOf(container), PwaMode.native);

      container.read(globalModelNumberProvider.notifier).state = _notDuModel;
      await pumpEventQueue();

      expect(modeOf(container), PwaMode.native);
    });

    test('keeps the banner hidden for 30 days after a dismissal', () async {
      SharedPreferences.setMockInitialValues({
        'pwa_prompt_dismissed_timestamp': DateTime.now()
            .subtract(const Duration(days: 29))
            .millisecondsSinceEpoch,
      });
      final browser = _FakePwaLogic();
      final container = start(browser, modelNumber: _notDuModel);
      await pumpEventQueue();

      browser.offerInstall(BeforeInstallPromptEvent());
      await pumpEventQueue();

      expect(modeOf(container), PwaMode.none);
    });

    test('keeps the banner hidden when the app runs installed (standalone)',
        () async {
      final browser = _FakePwaLogic(isStandalone: true);
      final container = start(browser, modelNumber: _notDuModel);
      await pumpEventQueue();

      browser.offerInstall(BeforeInstallPromptEvent());
      await pumpEventQueue();

      expect(modeOf(container), PwaMode.none);
    });
  });

  group('the native banner goes away', () {
    late _FakePwaLogic browser;
    late BeforeInstallPromptEvent offered;
    late ProviderContainer container;

    setUp(() async {
      browser = _FakePwaLogic();
      offered = BeforeInstallPromptEvent();
      container = start(browser, modelNumber: _notDuModel);
      await pumpEventQueue();
      browser.offerInstall(offered);
      await pumpEventQueue();
      expect(modeOf(container), PwaMode.native);
    });

    test('when the user installs from it: the browser shows its prompt',
        () async {
      await container.read(pwaInstallServiceProvider.notifier).promptInstall();

      expect(browser.prompted, [same(offered)]);
      expect(modeOf(container), PwaMode.none);
    });

    test('when the user dismisses it', () async {
      await container.read(pwaInstallServiceProvider.notifier).dismiss();

      expect(modeOf(container), PwaMode.none);
    });

    test('when the browser reports the app installed', () async {
      browser.appInstalled();

      expect(modeOf(container), PwaMode.none);
    });
  });

  group('Safari, which has no install prompt', () {
    test('iOS shows the iOS instructions, on a router that is not a DU model',
        () async {
      final container =
          start(_FakePwaLogic(isIOS: true), modelNumber: _notDuModel);
      await pumpEventQueue();

      expect(modeOf(container), PwaMode.ios);
    });

    test(
        'Mac Safari shows the Mac instructions, on a router that is not a DU '
        'model', () async {
      final container =
          start(_FakePwaLogic(isMacSafari: true), modelNumber: _notDuModel);
      await pumpEventQueue();

      expect(modeOf(container), PwaMode.mac);
    });
  });

  test('off the web, never listens to the browser and shows no banner',
      () async {
    final browser =
        _FakePwaLogic(earlyEvent: BeforeInstallPromptEvent(), isIOS: true);
    final container = start(browser, isWeb: false, modelNumber: _notDuModel);
    await pumpEventQueue();

    expect(browser.isListening, isFalse);
    expect(modeOf(container), PwaMode.none);
  });
}
