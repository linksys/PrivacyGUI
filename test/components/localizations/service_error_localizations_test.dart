import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/models/usp_operation_result.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

/// These tests assert the TYPE/CODE → l10n-key mapping rather than the literal
/// English text, so they stay green when copy changes but break the moment the
/// mapping drifts. The expected value is `loc(ctx).errorXxx`, captured from the
/// same context, never a hardcoded string.

UspErrorDetail _detail(int code) =>
    UspErrorDetail(requestedPath: 'Device.X.1.', errorCode: code, errorMessage: 'raw');

UspCompleteFailureError _completeWith(int code) =>
    UspCompleteFailureError(summary: 's', failures: [_detail(code)]);

void main() {
  // Pumps a minimal localized widget tree and hands the BuildContext back so
  // tests can call both localizeServiceError(ctx, ...) and loc(ctx).
  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (c) {
        captured = c;
        return const SizedBox();
      }),
    ));
    return captured;
  }

  group('localizeServiceError — type → key', () {
    testWidgets('maps each sealed subtype to its l10n string', (tester) async {
      final ctx = await pumpContext(tester);
      final l = loc(ctx);

      final cases = <ServiceError, String>{
        const NotAuthenticatedError(): l.errorNotAuthenticated,
        const InvalidCredentialsError(): l.errorInvalidCredentials,
        const SessionTokenExpiredError(): l.errorSessionExpired,
        const InvalidSessionTokenError(): l.errorInvalidSessionToken,
        const UnauthorizedError(): l.errorUnauthorized,
        const ResourceNotFoundError(): l.errorResourceNotFound,
        const InvalidInputError(): l.errorInvalidInput,
        const NetworkError(): l.errorNetwork,
        const ConnectivityError(): l.errorConnectivity,
        const TimeoutError(): l.errorTimeout,
        const ServiceNotInitializedError(): l.errorServiceNotReady,
        // Infrastructure-level types fall back to the generic message.
        const StorageError(): l.errorUnexpected,
        const SerialNumberMismatchError(expected: 'a', actual: 'b'):
            l.errorUnexpected,
      };

      cases.forEach((error, expected) {
        expect(localizeServiceError(ctx, error), expected,
            reason: '${error.runtimeType} should map to its l10n key');
      });
    });

    testWidgets('UnexpectedError surfaces detail when present, else fallback',
        (tester) async {
      final ctx = await pumpContext(tester);
      final l = loc(ctx);

      expect(localizeServiceError(ctx, const UnexpectedError(detail: 'boom')),
          'boom');
      expect(localizeServiceError(ctx, const UnexpectedError()),
          l.errorUnexpected);
    });

    testWidgets('non-ServiceError falls back to errorUnexpected',
        (tester) async {
      final ctx = await pumpContext(tester);
      final l = loc(ctx);

      expect(localizeServiceError(ctx, Exception('not a service error')),
          l.errorUnexpected);
      expect(localizeServiceError(ctx, 'plain string'), l.errorUnexpected);
    });
  });

  group('batch (_localizeBatch / _localizeFaultCode) — first failure code', () {
    testWidgets('invalid-input codes → errorInvalidInput', (tester) async {
      final ctx = await pumpContext(tester);
      final l = loc(ctx);
      for (final code in [7004, 7005, 7006, 9008]) {
        expect(localizeServiceError(ctx, _completeWith(code)), l.errorInvalidInput,
            reason: 'code $code should map to errorInvalidInput');
      }
    });

    testWidgets('not-found codes → errorResourceNotFound', (tester) async {
      final ctx = await pumpContext(tester);
      final l = loc(ctx);
      for (final code in [7026, 7027, 9005, 9007]) {
        expect(localizeServiceError(ctx, _completeWith(code)),
            l.errorResourceNotFound,
            reason: 'code $code should map to errorResourceNotFound');
      }
    });

    testWidgets('9001 → errorUnauthorized', (tester) async {
      final ctx = await pumpContext(tester);
      expect(localizeServiceError(ctx, _completeWith(9001)),
          loc(ctx).errorUnauthorized);
    });

    testWidgets('9999 (client transport, never reached router) → errorNetwork',
        (tester) async {
      final ctx = await pumpContext(tester);
      expect(localizeServiceError(ctx, _completeWith(9999)),
          loc(ctx).errorNetwork);
    });

    testWidgets('unknown vendor code → errorUnexpected (no raw text leak)',
        (tester) async {
      final ctx = await pumpContext(tester);
      expect(localizeServiceError(ctx, _completeWith(7099)),
          loc(ctx).errorUnexpected);
    });

    testWidgets('empty failures list → errorUnexpected', (tester) async {
      final ctx = await pumpContext(tester);
      expect(
          localizeServiceError(
              ctx, const UspCompleteFailureError(summary: 's', failures: [])),
          loc(ctx).errorUnexpected);
    });

    testWidgets('uses the FIRST failure when several are present',
        (tester) async {
      final ctx = await pumpContext(tester);
      final error = UspCompleteFailureError(
        summary: 's',
        failures: [_detail(9001), _detail(7006)],
      );
      // 9001 is first → unauthorized, not invalidInput.
      expect(localizeServiceError(ctx, error), loc(ctx).errorUnauthorized);
    });

    testWidgets('UspPartialFailureError also localizes via first failure',
        (tester) async {
      final ctx = await pumpContext(tester);
      final error = UspPartialFailureError(
        summary: 's',
        successPaths: const ['Device.Y.1.'],
        failures: [_detail(7026)],
      );
      expect(localizeServiceError(ctx, error), loc(ctx).errorResourceNotFound);
    });
  });
}
