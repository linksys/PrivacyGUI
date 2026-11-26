import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
// The printing plugin's platform interface, which it does not export: the
// stand-in for the system print dialog takes its place.
import 'package:printing/src/interface.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/util/qr_code.dart';
import 'package:privacy_gui/util/wifi_credential.dart';

/// The system print dialog: lays out what it is handed, as the platform does
/// once the user picks a printer, or fails with [failure].
class _PrintDialog extends PrintingPlatform {
  final List<Uint8List> printed = [];
  Object? failure;

  @override
  Future<bool> layoutPdf(
    Printer? printer,
    LayoutCallback onLayout,
    String name,
    PdfPageFormat format,
    bool dynamicLayout,
    bool usePrinterSettings,
    OutputType outputType,
    bool forceCustomPrintPaper,
  ) async {
    if (failure != null) throw failure!;
    printed.add(await onLayout(format));
    return true;
  }

  // Nothing else of the plugin is used.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// The content streams of [pdf], inflated.
List<String> _contents(Uint8List pdf) {
  final raw = latin1.decode(pdf);
  final contents = <String>[];
  for (final start in RegExp(r'(?<!end)stream\r?\n').allMatches(raw)) {
    final end = raw.indexOf('endstream', start.end);
    if (end < 0) continue;
    try {
      contents.add(latin1.decode(zlib.decode(pdf.sublist(start.end, end))));
    } on FormatException {
      // An image or font, not compressed page content.
    }
  }
  return contents;
}

/// The words the page shows, in the order it draws them.
List<String> _words(Uint8List pdf) => [
      for (final content in _contents(pdf))
        ...RegExp(r'\[\((.*?)\)\]TJ').allMatches(content).map((m) => m[1]!),
    ];

/// A 1 x 1 PNG, the smallest QR code image the page can hold.
final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');

void main() {
  group('createWiFiQRCode', () {
    // Codes that fit version 4 must keep printing and downloading exactly as
    // they always have. The digest was recorded from the version-4-only
    // implementation before longer codes were allowed.
    test('a name and password that fit version 4 keep their image', () async {
      final bytes = await createWiFiQRCode(const WiFiCredential(
        ssid: 'Linksys03041',
        password: 'FakeWiFi1@',
        type: SecurityType.wpa,
      ));

      expect(md5.convert(bytes).toString(), '9172faa30623f1288295e56353491d77');
    });

    // 32 characters of name and a 64-character key are the longest WiFi
    // Settings accepts - far more than version 4 holds.
    test('the longest name and password still make an image', () async {
      final bytes = await createWiFiQRCode(WiFiCredential(
        ssid: 'N' * 32,
        password: 'a' * 64,
        type: SecurityType.wpa,
      ));

      expect(image.decodePng(bytes), isNotNull);
    });
  });

  group('printWiFiQRCode', () {
    late _PrintDialog dialog;
    late PrintingPlatform plugin;
    late BuildContext context;

    setUp(() {
      plugin = PrintingPlatform.instance;
      dialog = _PrintDialog();
      PrintingPlatform.instance = dialog;
    });

    tearDown(() => PrintingPlatform.instance = plugin);

    Future<void> openEnglishApp(WidgetTester tester) =>
        tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (built) {
            context = built;
            return const SizedBox();
          }),
        ));

    testWidgets('prints one page with the app, the name, the password and '
        'the code', (tester) async {
      await openEnglishApp(tester);

      await tester.runAsync(() => printWiFiQRCode(
          context, Uint8List.fromList(_png), 'MyHome', 'secret-123'));

      final pdf = dialog.printed.single;
      expect(_words(pdf), [
        'Linksys', 'Now', //
        'WiFi', 'SSID:', 'MyHome', //
        'WiFi', 'password:', 'secret-123',
      ]);
      final drawn = _contents(pdf).join();
      expect(RegExp(r'/I\d+ Do').allMatches(drawn), hasLength(1));
      expect(RegExp(r'/Type\s*/Page\b(?!s)').allMatches(latin1.decode(pdf)),
          hasLength(1));
    });

    testWidgets('does not throw when the print fails', (tester) async {
      await openEnglishApp(tester);
      dialog.failure = Exception('no printer');

      await tester.runAsync(() => printWiFiQRCode(
          context, Uint8List.fromList(_png), 'MyHome', 'secret-123'));

      expect(dialog.printed, isEmpty);
    });
  });
}
