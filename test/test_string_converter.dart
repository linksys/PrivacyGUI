
import 'dart:convert';
import 'dart:typed_data';

import 'package:linksys_moab/utils.dart';
import 'package:test/test.dart';

void main() {
  group('test string conveter', () {
    test('test encoded Chinese', () async {
      const test = '中文';
      Utils.fullStringEncoded(test);
    });
  });
}
