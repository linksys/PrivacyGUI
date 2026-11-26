import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_state.dart';

void main() {
  final image = Uint8List.fromList([0x27, 0x05, 0x19, 0x56]);

  group('ManualUpdateInstalling', () {
    testWidgets('counts the progress up by 4 a second while it runs',
        (tester) async {
      final installing = ManualUpdateInstalling(0);
      var redraws = 0;

      installing.start((update) {
        update();
        redraws++;
      });
      await tester.pump(const Duration(seconds: 3));

      expect(installing.progress, 8);
      expect(redraws, 3);

      installing.stop();
      await tester.pump(const Duration(seconds: 3));

      expect(installing.progress, 8);
      expect(redraws, 3);
    });

    test('copyWith changes the progress, and keeps it when given none', () {
      final installing = ManualUpdateInstalling(40);

      expect(installing.copyWith(64).progress, 64);
      expect(installing.copyWith(null).progress, 40);
      expect(installing.copyWith(null), isNot(same(installing)));
    });

    test('stopping before it starts does nothing', () {
      expect(() => ManualUpdateInstalling(0).stop(), returnsNormally);
      expect(() => ManualUpdateRebooting().stop(), returnsNormally);
    });
  });

  group('FileInfo', () {
    test('writes the file as its name and its bytes in base64', () {
      expect(FileInfo(name: 'fw.bin', bytes: image).toMap(),
          {'name': 'fw.bin', 'bytes': 'JwUZVg=='});
    });

    test('reads back the file it wrote', () {
      final file = FileInfo(name: 'fw.bin', bytes: image);

      expect(FileInfo.fromJson(file.toJson()), file);
    });

    test('reads a missing name and missing bytes as empty', () {
      final file = FileInfo.fromMap(const {});

      expect(file.name, '');
      expect(file.bytes, isEmpty);
    });

    test('copyWith changes what it is given and keeps the rest', () {
      final file = FileInfo(name: 'fw.bin', bytes: image);
      final other = Uint8List.fromList([0x01, 0x02]);

      expect(file.copyWith(name: 'b'), FileInfo(name: 'b', bytes: image));
      expect(
          file.copyWith(bytes: other), FileInfo(name: 'fw.bin', bytes: other));
    });
  });

  group('ManualFirmwareUpdateState', () {
    test('writes the file and the step of the update', () {
      expect(
        ManualFirmwareUpdateState(
          file: FileInfo(name: 'fw.bin', bytes: image),
          status: ManualUpdateInstalling(40),
        ).toMap(),
        {
          'file': {'name': 'fw.bin', 'bytes': 'JwUZVg=='},
          'status': {'type': 'installing', 'progress': 40},
        },
      );
      expect(
          ManualFirmwareUpdateState(status: ManualUpdateRebooting()).toMap(), {
        'file': null,
        'status': {'type': 'rebooting'},
      });
    });

    test('reads back an installing update with its progress', () {
      final state =
          ManualFirmwareUpdateState.fromJson(ManualFirmwareUpdateState(
        file: FileInfo(name: 'fw.bin', bytes: image),
        status: ManualUpdateInstalling(40),
      ).toJson());

      expect(state.file, FileInfo(name: 'fw.bin', bytes: image));
      expect(
          state.status,
          isA<ManualUpdateInstalling>()
              .having((s) => s.progress, 'progress', 40));
    });

    test('reads back a rebooting update, and no update', () {
      expect(
          ManualFirmwareUpdateState.fromJson(
                  ManualFirmwareUpdateState(status: ManualUpdateRebooting())
                      .toJson())
              .status,
          isA<ManualUpdateRebooting>());
      expect(
          ManualFirmwareUpdateState.fromJson(
              const ManualFirmwareUpdateState().toJson()),
          const ManualFirmwareUpdateState());
    });

    test('copyWith can clear the file and keep the status', () {
      final rebooting = ManualUpdateRebooting();
      final state = ManualFirmwareUpdateState(
        file: FileInfo(name: 'fw.bin', bytes: image),
        status: rebooting,
      );

      expect(state.copyWith(file: () => null),
          ManualFirmwareUpdateState(status: rebooting));
      expect(state.copyWith(), state);
    });
  });
}
