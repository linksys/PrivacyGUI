import 'package:linksys_app/utils.dart';
import 'package:test/test.dart';

void main() {
  group('test json mask', () {
    test('username case', () async {
      const str = '''
        [I] TIME: 2022-08-10T08:46:51.856634 
        REQUEST---------------------------------------------------
        URL: https://qa-us1-api.linksys.cloud/v1/auth/login/prepare, METHOD: POST
        HEADERS: {content-type: application/json; charset=utf-8, accept: application/json}
        BODY: {"username":"austin.chang@gmail.com"}
        ---------------------------------------------------REQUEST END
      ''';
      final actual = Utils.maskJsonValue(str, ['username']);
      expect(actual.indexOf('austin.chang@gmail.com'), -1);
    });

    test('password case', () async {
      const str = '''
        [I] TIME: 2022-08-09T23:27:33.687797
        REQUEST---------------------------------------------------
        URL: https://qa-us1-api.linksys.cloud/v1/auth/login/password, METHOD: POST
        HEADERS: {content-type: application/json; charset=utf-8, accept: application/json}
        BODY: {"token":"4EE7E2CE-356D-4538-B769-FEB4D41FB05C","password":"Linksys123!"}
        ---------------------------------------------------REQUEST END
      ''';
      final actual = Utils.maskJsonValue(str, ['password']);
      expect(actual.indexOf('Linksys123!'), -1);
    });

  });
}
