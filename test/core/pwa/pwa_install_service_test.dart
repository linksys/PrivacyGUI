// PwaInstallService: whether the app offers to install itself as a web app,
// and the 30 days it keeps quiet after the user dismisses the offer.
//
// Deciding to offer (the model check, the standalone check, the iOS and Mac
// Safari prompts and the browser's install event) happens only on the web:
// every path to it is behind kIsWeb, which is false on the Dart VM.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/pwa/pwa_install_service.dart';
import 'package:privacy_gui/providers/global_model_number_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dismissedKey = 'pwa_prompt_dismissed_timestamp';
const _day = Duration(days: 1);

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  PwaInstallService service() =>
      container.read(pwaInstallServiceProvider.notifier);

  int daysAgo(int days) =>
      DateTime.now().subtract(_day * days).millisecondsSinceEpoch;

  test('off the web, never offers to install, on any router', () {
    expect(container.read(pwaInstallServiceProvider), PwaMode.none);

    container.read(globalModelNumberProvider.notifier).state = 'M63TS-EU';

    expect(container.read(pwaInstallServiceProvider), PwaMode.none);
    expect(service().isIOS, isFalse);
    expect(service().isMacSafari, isFalse);
    expect(service().isStandalone, isFalse);
  });

  group('dismiss', () {
    test('hides the offer and remembers when', () async {
      final before = DateTime.now().millisecondsSinceEpoch;

      await service().dismiss();

      expect(container.read(pwaInstallServiceProvider), PwaMode.none);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(_dismissedKey),
          inInclusiveRange(before, DateTime.now().millisecondsSinceEpoch));
      expect(await service().isDismissedRecently(), isTrue);
    });
  });

  group('isDismissedRecently', () {
    test('is false when the offer was never dismissed', () async {
      expect(await service().isDismissedRecently(), isFalse);
    });

    test('is true for 30 days after a dismissal', () async {
      SharedPreferences.setMockInitialValues({_dismissedKey: daysAgo(29)});

      expect(await service().isDismissedRecently(), isTrue);
    });

    test('is false once 30 days have passed', () async {
      SharedPreferences.setMockInitialValues({_dismissedKey: daysAgo(30)});

      expect(await service().isDismissedRecently(), isFalse);
    });
  });

  test('promptInstall does nothing before the browser offers an install',
      () async {
    await service().promptInstall();

    expect(container.read(pwaInstallServiceProvider), PwaMode.none);
  });
}
