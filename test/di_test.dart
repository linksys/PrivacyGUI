import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/di.dart';

void main() {
  group('canUseAppOriginUspClient', () {
    final original = BuildConfig.forceCommandType;

    tearDown(() {
      BuildConfig.forceCommandType = original;
    });

    test('allows the boot client in a Local build', () {
      BuildConfig.forceCommandType = ForceCommand.local;

      expect(canUseAppOriginUspClient(), isTrue);
    });

    test('allows the boot client when no mode is forced', () {
      BuildConfig.forceCommandType = ForceCommand.none;

      expect(canUseAppOriginUspClient(), isTrue);
    });

    test('rejects the boot client in a Remote Assistance build', () {
      // The app is served from static hosting, not by the router — a client
      // built on Uri.base.origin would answer no USP request, and whoever read
      // uspClientProvider first would cache it. Only activate() may build the
      // client in this mode.
      BuildConfig.forceCommandType = ForceCommand.remote;

      expect(canUseAppOriginUspClient(), isFalse);
    });
  });
}
