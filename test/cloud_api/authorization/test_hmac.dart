
import 'package:flutter_test/flutter_test.dart';
import 'package:linksys_moab/util/extensions.dart';


void main() {
  group('test hmac algorithm', () {

    test('Test sample', () async {
      const query = 'grant_type=password';
      const body        = 'username=foo@bar.com&password=some_secret';
      const timestamp   = 1592972449000;
      const secret      = 'foo';

      final digestHex = '$query\n$body\n$timestamp'.toHmacSHA256(secret);

      expect(digestHex, 'a37a3a926b6e7d73579d30d1e77f2bc60847a2cbdfa940b12544ffe3a4eb7b46');
      
    });
  });
}
