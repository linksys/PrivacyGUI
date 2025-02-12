import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Future<Uint8List> snapshotWidget(GlobalKey globalKey,
    [ui.ImageByteFormat format = ui.ImageByteFormat.png]) async {
  RenderRepaintBoundary boundary =
      globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  ui.Image image =
      await boundary.toImage(pixelRatio: 3.0); // Adjust pixelRatio for quality
  ByteData? byteData = await image.toByteData(format: format);
  return byteData!.buffer.asUint8List();
}
