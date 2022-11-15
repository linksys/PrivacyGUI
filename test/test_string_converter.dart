
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:linksys_moab/utils.dart';
import 'package:test/test.dart';

// TODO test supported languages
void main() {
  group('test string converter', () {
    test('test encoded Chinese', () async {
      const test = '中文';
      final encoded = Utils.fullStringEncoded(test);
      expect(Utils.fullStringDecoded(encoded), test);
    });
    test('test encoded Tai', () async {
      const test = 'ทดสอบ';
      final encoded = Utils.fullStringEncoded(test);
      expect(Utils.fullStringDecoded(encoded), test);
    });
  });
}
