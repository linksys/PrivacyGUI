import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';
import 'package:privacy_gui/page/_shared/models/timezone_info.dart';

void main() {
  // `formatGmtOffset` was lifted out of `TimeZoneInfo.offsetDisplayText` for
  // #1609, so that the cards can format an offset that has no `TimeZoneInfo` at
  // all — the one the device reported next to its clock, which is all we can say
  // about a zone `kTimeZoneDefinitions` does not carry. The fractional and
  // negative cases are here because that is where a hand-rolled formatter goes
  // wrong: the sign belongs to the whole offset, not to the hour field.
  group('formatGmtOffset', () {
    test('zero is signed positive', () {
      expect(formatGmtOffset(0), 'GMT+00:00');
    });

    test('whole hours, both directions', () {
      expect(formatGmtOffset(480), 'GMT+08:00');
      expect(formatGmtOffset(-480), 'GMT-08:00');
    });

    test('pads a single-digit hour', () {
      expect(formatGmtOffset(60), 'GMT+01:00');
      expect(formatGmtOffset(-60), 'GMT-01:00');
    });

    test('fractional offsets keep their minutes', () {
      expect(formatGmtOffset(330), 'GMT+05:30');
      expect(formatGmtOffset(345), 'GMT+05:45');
      expect(formatGmtOffset(-210), 'GMT-03:30');
    });

    test('the largest offsets the device publishes', () {
      // `<+14>-14` (Pacific/Kiritimati) and `<-12>12` are real rows in
      // `Device.Time.X_LINKSYS_SupportedZones`.
      expect(formatGmtOffset(840), 'GMT+14:00');
      expect(formatGmtOffset(-720), 'GMT-12:00');
    });
  });

  group('TimeZoneInfo.offsetDisplayText', () {
    test('delegates to formatGmtOffset for every defined zone', () {
      for (final tz in kTimeZoneDefinitions) {
        expect(tz.offsetDisplayText, formatGmtOffset(tz.utcOffsetMinutes),
            reason: '${tz.timeZoneID} formats its own offset differently from '
                'the shared formatter.');
      }
    });
  });
}
