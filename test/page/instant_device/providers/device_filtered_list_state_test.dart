// The Devices page's filter settings as a map: the shape test/test_data gives
// the views, and what the state writes.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';

import '../../../test_data/device_filter_config_test_state.dart';

void main() {
  test('reads the filter as the test data writes it', () {
    final filter = DeviceFilterConfigState.fromMap(deviceFilterConfigTestState);

    expect(filter.connectionFilter, isTrue);
    expect(filter.nodeFilter, ['6c73112b-b6d1-4bfd-9a8c-80691abb46cc']);
    expect(filter.wifiFilter, ['Linksys03041', 'Linksys03041-guest']);
    expect(filter.bandFilter, ['2.4GHz', '5GHz', 'Ethernet']);
    expect(filter.showOrphanNodes, isFalse);
  });

  test('writes back the map it was read from, and reads its JSON back', () {
    final filter = DeviceFilterConfigState.fromMap(deviceFilterConfigTestState);

    expect(filter.toMap(), deviceFilterConfigTestState);
    expect(DeviceFilterConfigState.fromJson(filter.toJson()), filter);
  });

  test('reads a filter with no connection or orphan choice as both off', () {
    final filter = DeviceFilterConfigState.fromMap(const {
      'nodeFilter': <String>[],
      'wifiFilter': <String>[],
      'bandFilter': <String>[],
    });

    expect(filter.connectionFilter, isFalse);
    expect(filter.showOrphanNodes, isFalse);
  });

  test('a filter read twice is the same filter; a change to any choice is not',
      () {
    final filter = DeviceFilterConfigState.fromMap(deviceFilterConfigTestState);

    expect(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState), filter);
    for (final edited in [
      filter.copyWith(connectionFilter: false),
      filter.copyWith(nodeFilter: []),
      filter.copyWith(wifiFilter: ['Linksys03041']),
      filter.copyWith(bandFilter: ['5GHz']),
      filter.copyWith(showOrphanNodes: true),
    ]) {
      expect(edited, isNot(filter));
    }
  });

  test('an edit to one choice keeps the others', () {
    final filter = DeviceFilterConfigState.fromMap(deviceFilterConfigTestState);

    expect(filter.copyWith(showOrphanNodes: true).toMap(),
        {...deviceFilterConfigTestState, 'showOrphanNodes': true});
  });
}
