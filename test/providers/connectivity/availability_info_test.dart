// AvailabilityInfo: whether the cloud answered its status page
// (ConnectivityState.cloudAvailabilityInfo).

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/providers/connectivity/availability_info.dart';

// Values compared with one built as const are built at run time: two equal
// const values are one instance, so == would hold whatever props says.
void main() {
  test('starts by taking the cloud to be up', () {
    expect(AvailabilityInfo.init().isCloudOk, isTrue);
    expect(AvailabilityInfo.init(), AvailabilityInfo(isCloudOk: true));
  });

  group('copyWith', () {
    test('changes whether the cloud is up', () {
      expect(AvailabilityInfo.init().copyWith(isCloudOk: false).isCloudOk,
          isFalse);
    });

    test('keeps it when not given', () {
      expect(AvailabilityInfo(isCloudOk: false).copyWith().isCloudOk, isFalse);
    });
  });

  test('is equal when the cloud is up in both, and not when it differs', () {
    expect(AvailabilityInfo(isCloudOk: false),
        const AvailabilityInfo(isCloudOk: false));
    expect(AvailabilityInfo(isCloudOk: false),
        isNot(AvailabilityInfo(isCloudOk: true)));
  });
}
