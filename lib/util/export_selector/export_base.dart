import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<ShareResult?> exportFile(
        {required String content,
        required String fileName,
        String? text,
        String? subject}) async =>
    throw UnimplementedError('Unsupported Platform!');
    
Future<ShareResult?> exportFileFromBytes(
        {required Uint8List utf8Bytes,
        required String fileName,
        String? text,
        String? subject}) async =>
    throw UnimplementedError('Unsupported Platform!');
