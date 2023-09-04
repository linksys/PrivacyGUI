import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:linksys_app/core/cloud/model/cloud_account.dart';

void main() {
  testWidgets('cloud account convert', (tester) async {
    const str =
        '{"preferences": {"locale": {"language": "en", "country": "US"}, "newsletterOptIn": false, "fakeSubscription": false, "notifications": {"notification": [{"type": "PUSH", "value": "4D70BC04-E1E3-411E-9D13-23C0946E719D"}]}, "mfaEnabled": true, "mobile": {"countryCode": "+886", "phoneNumber": "908720012"}}}';
    final data = CAPreferences.fromJson(jsonDecode(str)['preferences']);
    expect(data, isA<CAPreferences>());
    expect(data.locale?.language, 'en');
    expect(data.locale?.country, 'US');
    expect(data.newsletterOptIn, 'false');
    expect(data.fakeSubscription, 'false');
    expect(data.notifications?.notifications.length, 1);
    expect(data.mobile?.countryCode, '+886');
    expect(data.mobile?.phoneNumber, '908720012');
    expect(data.mfaEnabled, true);
  });
}
