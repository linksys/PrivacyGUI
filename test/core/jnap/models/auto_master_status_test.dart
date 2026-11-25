import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';

void main() {
  test('reads each status the router sends', () {
    expect([
      for (final value in ['Idle', 'Running', 'Complete', 'Failed'])
        GetAutoMasterStatusResponse.fromMap({'autoMasterStatus': value})
            .autoMasterStatus,
    ], AutoMasterStatus.values);
  });

  test('reads no status from a value it does not know, of any type', () {
    expect(
        GetAutoMasterStatusResponse.fromMap(const {'autoMasterStatus': 'Done'})
            .autoMasterStatus,
        isNull);
    expect(
        GetAutoMasterStatusResponse.fromMap(const {'autoMasterStatus': 1})
            .autoMasterStatus,
        isNull);
    expect(
        GetAutoMasterStatusResponse.fromMap(const {}).autoMasterStatus, isNull);
  });

  test('writes back the router\'s own names', () {
    expect(
        const GetAutoMasterStatusResponse(
                autoMasterStatus: AutoMasterStatus.complete)
            .toMap(),
        {'autoMasterStatus': 'Complete'});
    expect(const GetAutoMasterStatusResponse().toMap(),
        {'autoMasterStatus': null});
    expect(
        const GetAutoMasterStatusResponse(
            autoMasterStatus: AutoMasterStatus.failed),
        isNot(const GetAutoMasterStatusResponse(
            autoMasterStatus: AutoMasterStatus.running)));
  });

  test('reads back each status it writes', () {
    for (final value in ['Idle', 'Running', 'Complete', 'Failed']) {
      final response =
          GetAutoMasterStatusResponse.fromMap({'autoMasterStatus': value});

      expect(GetAutoMasterStatusResponse.fromMap(response.toMap()), response);
      expect(response.toMap(), {'autoMasterStatus': value});
    }
  });
}
