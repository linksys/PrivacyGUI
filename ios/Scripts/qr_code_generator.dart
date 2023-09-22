import 'dart:io';

import 'package:image/image.dart';
import 'package:qr/qr.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    exit(0);
  }
  final String data = args.first;
  final qrCode = QrCode(4, QrErrorCorrectLevel.L)..addData(data);
  final qr = QrImage(qrCode);
  final image = await _drawQRCodeDefault(qr);

  File file = File('ios/Scripts/InHouse/qr_code.png');
  if (!file.existsSync()) {
    file.createSync(recursive: true);
  }
  file.writeAsBytesSync(encodePng(image));
}

Future<Image> _drawQRCodeDefault(QrImage qr) async {
  int size = 360;
  int blockSize = (size / qr.moduleCount).floor() + 2;
  int imageSize = (blockSize * qr.moduleCount) + (blockSize * 2);

  var img = Image(
    width: imageSize,
    height: imageSize,
  );
  img.clear(ColorFloat16.rgb(255, 255, 255));

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
        drawLine(img,
            x1: xx,
            y1: d,
            x2: xx + blockSize,
            y2: d,
            color: ColorUint8.rgb(0, 75, 193));
      }
    }
    str += '\n';
  }
  var icon = await decodePngFile('ios/Scripts/InHouse/ic_launcher.png');
  icon = copyResize(icon!, width: 64, height: 64);
  compositeImage(img, icon, center: true);
  print(str);

  return copyResize(img, width: size, height: size);
}
