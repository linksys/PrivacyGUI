import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/send_sysinfo_email.dart';

void main() {
  test('writes the addresses the troubleshooting page sends the report to', () {
    const email = SendSysinfoEmail(
        addressList: ['support@example.com', 'me@example.com']);

    expect(email.toJson(), {
      'addressList': ['support@example.com', 'me@example.com'],
    });
  });

  test('copyWith changes only what it names', () {
    const email = SendSysinfoEmail(addressList: ['support@example.com']);

    expect(email.copyWith(addressList: ['me@example.com']).addressList,
        ['me@example.com']);
    expect(email.copyWith(), email);
  });
}
