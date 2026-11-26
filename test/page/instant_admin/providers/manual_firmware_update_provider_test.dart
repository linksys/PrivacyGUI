import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_state.dart';

void main() {
  late ProviderContainer container;

  ManualFirmwareUpdateNotifier notifier() =>
      container.read(manualFirmwareUpdateProvider.notifier);
  ManualFirmwareUpdateState page() =>
      container.read(manualFirmwareUpdateProvider);

  setUp(() {
    container = ProviderContainer();
    // The provider is autoDispose: keep it alive as the page does.
    container.listen(manualFirmwareUpdateProvider, (_, __) {});
  });

  tearDown(() => container.dispose());

  final image = Uint8List.fromList([0x27, 0x05, 0x19, 0x56]);

  test('starts with no file chosen and nothing in progress', () {
    expect(page().file, isNull);
    expect(page().status, isNull);
  });

  test('holds the file the user chose, until they remove it', () {
    notifier().setFile('FW_MX5500_1.1.10.bin', image);

    expect(page().file, FileInfo(name: 'FW_MX5500_1.1.10.bin', bytes: image));

    notifier().removeFile();

    expect(page().file, isNull);
  });

  test('keeps the chosen file while the update runs', () {
    notifier()
      ..setFile('FW_MX5500_1.1.10.bin', image)
      ..setStatus(ManualUpdateInstalling(0));

    expect(page().status, isA<ManualUpdateInstalling>());
    expect(page().file?.name, 'FW_MX5500_1.1.10.bin');

    notifier().setStatus(ManualUpdateRebooting());

    expect(page().status, isA<ManualUpdateRebooting>());

    notifier().setStatus(null);

    expect(page().status, isNull);
    expect(page().file?.name, 'FW_MX5500_1.1.10.bin');
  });

  testWidgets('reset stops the progress and forgets the file', (tester) async {
    final installing = ManualUpdateInstalling(0);
    notifier()
      ..setFile('FW_MX5500_1.1.10.bin', image)
      ..setStatus(installing);
    installing.start((update) => update());
    await tester.pump(const Duration(seconds: 3));
    final progressAtReset = installing.progress;

    notifier().reset();
    await tester.pump(const Duration(seconds: 3));

    expect(installing.progress, progressAtReset);
    expect(page().file, isNull);
    expect(page().status, isNull);
  });
}
