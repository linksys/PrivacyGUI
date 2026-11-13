import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/ddns/models/ddns_rules.dart';
import 'package:privacy_gui/page/ddns/models/ddns_status.dart';

void main() {
  group('DdnsStatus - copyWith', () {
    test('starts loading with no error and no field errors', () {
      const status = DdnsStatus();

      expect(status.isLoading, isTrue);
      expect(status.isSaving, isFalse);
      expect(status.error, isNull);
      expect(status.fieldErrors, isEmpty);
    });

    test('replaces the fields given and keeps the rest', () {
      const status = DdnsStatus(isLoading: false);

      final next = status.copyWith(
        isSaving: true,
        fieldErrors: {DdnsField.hostname},
      );

      expect(next.isLoading, isFalse);
      expect(next.isSaving, isTrue);
      expect(next.fieldErrors, {DdnsField.hostname});
    });

    test('clearError drops the error', () {
      const status = DdnsStatus(error: NetworkError());

      expect(status.copyWith(clearError: true).error, isNull);
      expect(status.copyWith(isSaving: true).error, isA<NetworkError>());
    });
  });

  group('DdnsStatus - equality', () {
    test('compares every field', () {
      expect(const DdnsStatus(isLoading: false),
          const DdnsStatus(isLoading: false));
      expect(
        const DdnsStatus(isLoading: false),
        isNot(const DdnsStatus(
            isLoading: false, fieldErrors: {DdnsField.username})),
      );
    });
  });
}
