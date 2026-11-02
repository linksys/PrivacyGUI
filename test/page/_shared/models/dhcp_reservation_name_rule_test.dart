import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';

/// FW's reservation name rule (linksys/FWDEV#211; dhcpmngr `is_dns_label` in
/// linksys/feed_usp#54): empty, or at most 63 letters, digits and `-`, no `-`
/// at either end, unique in the pool.
void main() {
  DhcpReservationUIModel named(String name) => DhcpReservationUIModel(
      mac: 'AA:BB:CC:DD:EE:01', ip: '192.168.1.10', enable: true, name: name);

  String? check(String name,
          [List<DhcpReservationUIModel> others = const []]) =>
      DhcpReservationUIModel.validateName(name, others);

  test('an empty name is accepted', () {
    expect(check(''), isNull);
    expect(check('', [named('')]), isNull,
        reason: '"" is never sent, so two unnamed rows do not clash');
  });

  test('letters, digits and inner hyphens are accepted', () {
    for (final name in ['a', 'Z', '7', 'tv', 'Living-Room-TV-2', 'a-b-c']) {
      expect(check(name), isNull, reason: name);
    }
  });

  test('63 characters are accepted, 64 are not', () {
    expect(check('a' * 63), isNull);
    expect(check('a' * 64), DhcpReservationNameErrors.tooLong);
  });

  test('a hyphen at either end is refused', () {
    for (final name in ['-tv', 'tv-', '-', '--']) {
      expect(check(name), DhcpReservationNameErrors.invalid, reason: name);
    }
  });

  test('any other character is refused', () {
    for (final name in [
      'living room',
      'tv_1',
      'tv.lan',
      'café',
      'tv!',
      ' tv',
      'tv '
    ]) {
      expect(check(name), DhcpReservationNameErrors.invalid, reason: name);
    }
  });

  test('a name another reservation has is refused', () {
    expect(check('tv', [named('nas'), named('tv')]),
        DhcpReservationNameErrors.inUse);
    expect(check('tv', [named('nas')]), isNull);
  });

  test('a name is a field of the model, and of its equality', () {
    expect(named('a'), isNot(named('b')));
    expect(named('a').copyWith(name: 'b'), named('b'));
    expect(DhcpReservationUIModel(mac: 'a', ip: 'b', enable: true).name, '');
  });
}
