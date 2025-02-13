import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/util/wifi_credential.dart';
import 'package:qr/qr.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

// Not for WEB UI rendering by HTML
// Future<Uint8List> snapshotWidget(GlobalKey globalKey,
//     [ui.ImageByteFormat format = ui.ImageByteFormat.png]) async {
//   RenderRepaintBoundary boundary =
//       globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
//   ui.Image image =
//       await boundary.toImage(pixelRatio: 1.0); // Adjust pixelRatio for quality
//   ByteData? byteData = await image.toByteData(format: format);
//   return byteData!.buffer.asUint8List();
// }

Future<Uint8List> createWiFiQRCode(WiFiCredential wifiCredential) async {
  final qrCode = QrCode(4, QrErrorCorrectLevel.L)
    ..addData(wifiCredential.generate());
  final qrImage = QrImage(qrCode);
  return createQRCodeBytes(qrImage);
}

Future<Uint8List> createQRCodeBytes(QrImage qr, {int size = 360}) async {
  int blockSize = (size / qr.moduleCount).floor() + 2;
  int imageSize = (blockSize * qr.moduleCount) + (blockSize * 2);

  var img = image.Image(
    width: imageSize,
    height: imageSize,
  );
  img.clear(image.ColorFloat16.rgb(255, 255, 255));

  String str = '';
  for (var x = 0; x < qr.moduleCount; x++) {
    for (var y = 0; y < qr.moduleCount; y++) {
      if (qr.isDark(x, y) == false) {
        str += ' ';
        continue;
      }
      str += '*';
      int xx = (x * blockSize) + blockSize;
      int yy = (y * blockSize) + blockSize;

      for (var d = yy; d <= yy + blockSize; d++) {
        image.drawLine(img,
            x1: xx,
            y1: d,
            x2: xx + blockSize,
            y2: d,
            color: image.ColorUint8.rgb(0, 0, 0));
      }
    }
    str += '\n';
  }

  // TODO add icon in the center
  // var icon = await image.decodePngFile('./splash/img/branding-dark-1x.png.png');
  // icon = image.copyResize(icon!, width: 64, height: 64);
  // image.compositeImage(img, icon, center: true);
  // print(str);

  final result = image.copyResize(img, width: size, height: size);
  return image.encodePng(result);
}

Future<void> printWiFiQRCode(BuildContext context, Uint8List imageBytes,
    String ssid, String password) async {
  final image = pw.MemoryImage(imageBytes);
  final page = pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      build: (pw.Context pwContext) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(loc(context).appTitle,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                ),
                textScaleFactor: 2.0),
            pw.SizedBox(height: 8.0),
            pw.Text('WiFi SSID: $ssid',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.normal,
                ),
                textScaleFactor: 1.0),
            pw.Text('WiFi password: $password',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.normal,
                ),
                textScaleFactor: 1.0),
            pw.SizedBox(height: 16.0),
            pw.SizedBox(
              width: 200,
              height: 200,
              child: pw.Image(image),
            ),
          ],
        );
      });
  try {
    final doc = pw.Document();

    // Create Info Page
    doc.addPage(page);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => doc.save(),
    );
  } catch (e) {
    logger.e('Print page error', error: e);
  }
}
