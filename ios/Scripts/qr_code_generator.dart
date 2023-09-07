import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:qr/qr.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    exit(0);
  }
  final String data = args.first;
  final qrCode = QrCode(4, QrErrorCorrectLevel.L)
    ..addData(data);
  final qr = QrImage(qrCode);
  final image = _drawQRCodeDefault(qr);

  File file = File('ios/Scripts/InHouse/qr_code.png');
  if (!file.existsSync()) {
    file.createSync(recursive: true);
  }
  file.writeAsBytesSync(encodePng(image));
  
}

Image _drawQRCodeDefault(QrImage qr) {
  int size = 240;
  int blockSize = (size / qr.moduleCount).floor() + 2;
  int imageSize = (blockSize * qr.moduleCount) + (blockSize * 2);

  var img = Image(imageSize, imageSize);
  fill(img, Color.fromRgb(255, 255, 255));

  for (var x = 0; x < qr.moduleCount; x++) {
    for (var y = 0; y < qr.moduleCount; y++) {
      if (qr.isDark(x, y) == false) continue;
      int xx = (x * blockSize) + blockSize;
      int yy = (y * blockSize) + blockSize;
      fillRect(
          img, xx, yy, xx + blockSize, yy + blockSize, Color.fromRgb(0, 0, 0));
    }
  }

  return copyResize(img, width: size, height: size);
}
