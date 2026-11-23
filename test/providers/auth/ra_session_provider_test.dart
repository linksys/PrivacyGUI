import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/cloud/model/cloud_remote_assistance_info.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/providers/auth/ra_session.dart';
import 'package:privacy_gui/providers/auth/ra_session_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/cloud_boundary.dart';

// The remote assistance session as the router's owner holds it, from the
// support page: a PIN to hand the support agent, the session's time left, and
// ending it.

const _raSessions =
    '/cloud/remote-access-service/rest/remoteassistance/sessions';

Map<String, dynamic> _sessionList(List<String> ids) => {
      'remoteAssistanceSessions': [
        for (final id in ids)
          {
            'remoteAssistanceSession': {'remoteAssistanceSessionId': id},
          },
      ],
    };

Map<String, dynamic> _sessionInfo(int expiredIn) => {
      'remoteAssistanceSession': {
        'remoteAssistanceSessionId': 'S1',
        'status': 'ACTIVE',
        'expiredIn': expiredIn,
      },
    };

void main() {
  late CloudBoundary cloud;
  late ProviderContainer container;

  RASessionNotifier notifier() => container.read(raSessionProvider.notifier);
  RASession session() => container.read(raSessionProvider);

  setUp(() {
    SharedPreferences.setMockInitialValues(
        {pSelectedNetworkId: 'N1'});
    FlutterSecureStorage.setMockInitialValues({
      pSessionToken: jsonEncode({
        'access_token': 'owner-token',
        'token_type': 'Bearer',
        'expires_in': 3600,
      }),
    });
    // The selected network has one session, S1, unless a test says otherwise.
    cloud = CloudBoundary()
      ..answers('GET', _raSessions, json: _sessionList(['S1']));
    container = ProviderContainer(overrides: [
      cloudRepositoryProvider
          .overrideWithValue(LinksysCloudRepository(httpClient: cloud)),
    ]);
  });

  tearDown(() => container.dispose());

  group('raGenPin', () {
    test('asks the session of the selected network for a PIN', () async {
      cloud.answers('POST', '$_raSessions/pin', json: {
        'remoteAssistanceSession': {
          'remoteAssistanceSessionId': 'S1',
          'pin': '010794',
        },
      });

      final pin = await notifier().raGenPin();

      expect(pin, '010794');
      expect(cloud.requestsTo('$_raSessions/pin').single.json, {
        'remoteAssistanceSession': {'remoteAssistanceSessionId': 'S1'},
      });
      expect(cloud.requests.first.header('X-Linksys-Network-Id'), 'N1');
    });

    test('reports no session when the network has none', () async {
      cloud.answers('GET', _raSessions, json: _sessionList([]));

      await expectLater(
          notifier().raGenPin(), throwsA(isA<RANoSessionException>()));
      expect(cloud.requestsTo('$_raSessions/pin'), isEmpty);
    });

    test('reports a session already in progress', () async {
      cloud.answersError('POST', '$_raSessions/pin', 'SESSION_IN_PROGRESS');

      await expectLater(
          notifier().raGenPin(), throwsA(isA<RASessionInProgressException>()));
    });

    test('passes on any other PIN error as it came', () async {
      cloud.answersError('POST', '$_raSessions/pin', 'INVALID_PARAMETER');

      await expectLater(
          notifier().raGenPin(),
          throwsA(isA<ErrorResponse>()
              .having((e) => e.code, 'code', 'INVALID_PARAMETER')));
    });
  });

  group('raGetSessionInfo', () {
    test('reads the session and remembers its id', () async {
      cloud.answers('GET', '$_raSessions/S1', json: _sessionInfo(-1757));

      final info = await notifier().raGetSessionInfo();

      expect(info.expiredIn, -1757);
      expect(session().sessionId, 'S1');
    });

    test('asks for the session id only once', () async {
      cloud.answers('GET', '$_raSessions/S1', json: _sessionInfo(-1757));

      await notifier().raGetSessionInfo();
      await notifier().raGetSessionInfo();

      expect(cloud.requestsTo(_raSessions), hasLength(1));
      expect(cloud.requestsTo('$_raSessions/S1'), hasLength(2));
    });
  });

  group('raLogout', () {
    test('ends the session and forgets it', () async {
      cloud.answers(
          'DELETE', '/cloud/v1/guardians/remote-assistances/sessions/S1');

      await notifier().raLogout();

      final deletion = cloud.requests.last;
      expect(deletion.method, 'DELETE');
      expect(deletion.url.path, endsWith('/S1'));
      expect(session(), const RASession(sessionId: '', token: ''));
    });

    test('ends the session it already knows without asking for it', () async {
      cloud
        ..answers('GET', '$_raSessions/S1', json: _sessionInfo(-1757))
        ..answers(
            'DELETE', '/cloud/v1/guardians/remote-assistances/sessions/S1');
      await notifier().raGetSessionInfo();

      await notifier().raLogout();

      expect(cloud.requestsTo(_raSessions), hasLength(1));
    });

    test('passes on the error when the session cannot be ended',
        () async {
      cloud.answersError(
          'DELETE',
          '/cloud/v1/guardians/remote-assistances/sessions/S1',
          'SESSION_NOT_FOUND');

      await expectLater(notifier().raLogout(), throwsA(isA<ErrorResponse>()));
    });
  });

  group('following the session', () {
    // testWidgets, for its fake clock: the poll waits five real seconds
    // between reads.
    testWidgets('reads it again every five seconds while time is left',
        (tester) async {
      cloud.answers('GET', '$_raSessions/S1', json: _sessionInfo(-60000));
      final seen = <CloudRemoteAssistanceInfo>[];
      var ended = false;
      notifier().pollSessionInfo().listen(seen.add, onDone: () => ended = true);

      await tester.pump();
      expect(seen, hasLength(1));

      await tester.pump(const Duration(seconds: 5));
      expect(seen, hasLength(2));
      expect(ended, isFalse);

      cloud.answers('GET', '$_raSessions/S1', json: _sessionInfo(0));
      await tester.pump(const Duration(seconds: 5));
      expect(seen, hasLength(3));
      expect(seen.last.expiredIn, 0);

      await tester.pump(const Duration(seconds: 5));
      expect(ended, isTrue);
    });

    testWidgets('keeps reading down to the last moment of the session',
        (tester) async {
      cloud.answers('GET', '$_raSessions/S1', json: _sessionInfo(-1));
      final seen = <CloudRemoteAssistanceInfo>[];
      var ended = false;
      notifier().pollSessionInfo().listen(seen.add, onDone: () => ended = true);

      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      expect(seen, hasLength(2));
      // Let the session run out, so the poll ends and leaves no timer behind.
      cloud.answers('GET', '$_raSessions/S1', json: _sessionInfo(0));
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
      expect(ended, isTrue);
    });

    test('ends with an error when the session cannot be read', () async {
      cloud.answersError('GET', '$_raSessions/S1', 'SESSION_NOT_FOUND');

      await expectLater(
          notifier().pollSessionInfo(), emitsError(isA<ErrorResponse>()));
    });
  });
}
