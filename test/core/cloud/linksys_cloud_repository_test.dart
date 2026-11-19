import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';

import '../../common/cloud_boundary.dart';

// Remote assistance on the cloud: the account-side sessions and the Guardian
// sessions a support agent opens. The account login, OTP and the RA calls no
// code makes are deletion candidates (#1849) and are not tested here.

const _raSessions =
    '/cloud/remote-access-service/rest/remoteassistance/sessions';
const _raPin = '$_raSessions/pin';
const _guardianSessions = '/cloud/v1/guardians/remote-assistances/sessions';

void main() {
  late CloudBoundary cloud;
  late LinksysCloudRepository repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      pSessionToken: jsonEncode({
        'access_token': 'stored-token',
        'token_type': 'Bearer',
        'expires_in': 3600,
      }),
    });
    cloud = CloudBoundary();
    repository = LinksysCloudRepository(httpClient: cloud);
  });

  group('raGetSession', () {
    test('asks for the network sessions and returns the first', () async {
      cloud.answers('GET', _raSessions, json: {
        'remoteAssistanceSessions': [
          {
            'remoteAssistanceSession': {
              'remoteAssistanceSessionId': 'S1',
              'status': 'PENDING',
            },
          },
          {
            'remoteAssistanceSession': {'remoteAssistanceSessionId': 'S2'},
          },
        ],
      });

      final sessionId = await repository.raGetSession(networkId: 'N1');

      expect(sessionId, 'S1');
      final request = cloud.requests.single;
      expect(request.header('Authorization'),
          'LinksysUserAuth session_token="stored-token"');
      expect(request.header('X-Linksys-Network-Id'), 'N1');
    });

    test('sends an empty token when none is stored', () async {
      FlutterSecureStorage.setMockInitialValues({});
      cloud.answers('GET', _raSessions, json: {
        'remoteAssistanceSessions': [
          {
            'remoteAssistanceSession': {'remoteAssistanceSessionId': 'S1'},
          },
        ],
      });

      await repository.raGetSession(networkId: 'N1');

      expect(cloud.requests.single.header('Authorization'),
          'LinksysUserAuth session_token=""');
    });

    test('fails when the network has no session', () async {
      cloud.answers('GET', _raSessions,
          json: {'remoteAssistanceSessions': <Object>[]});

      await expectLater(
          repository.raGetSession(networkId: 'N1'), throwsA(isA<StateError>()));
    });

    test('reports the error the cloud answers with', () async {
      cloud.answersError('GET', _raSessions, 'INVALID_SESSION_TOKEN');

      await expectLater(
        repository.raGetSession(networkId: 'N1'),
        throwsA(isA<ErrorResponse>()
            .having((e) => e.code, 'code', 'INVALID_SESSION_TOKEN')),
      );
    });
  });

  group('raGetSessionInfo', () {
    test('reads the session the support agent sees', () async {
      cloud.answers('GET', '$_raSessions/S1', json: {
        'remoteAssistanceSession': {
          'remoteAssistanceSessionId': 'S1',
          'status': 'ACTIVE',
          'expiredIn': -1757,
          'createdAt': 1722240538000,
          'statusChangedAt': 1722240574000,
          'currentTime': 1722240580739,
        },
      });

      final info =
          await repository.raGetSessionInfo(networkId: 'N1', sessionId: 'S1');

      expect(info.remoteAssistanceSessionId, 'S1');
      expect(info.status, 'ACTIVE');
      expect(info.expiredIn, -1757);
      expect(cloud.requests.single.header('X-Linksys-Network-Id'), 'N1');
    });
  });

  group('getSessionInfo', () {
    final guardianSession = {
      'id': 'G1',
      'serialNumber': 'SN-MASTER',
      'modelNumber': 'MX6200',
      'status': 'ACTIVE',
      'expiredIn': -600,
      'createdAt': 1722240538000,
      'statusChangedAt': 1722240574000,
      'currentTime': 1722240580739,
    };

    test('reads a Guardian session with the token it is given', () async {
      cloud.answers('GET', '$_guardianSessions/G1', json: guardianSession);

      final info = await repository.getSessionInfo(
          token: 'agent-token', sessionId: 'G1');

      expect(info.id, 'G1');
      expect(info.serialNumber, 'SN-MASTER');
      expect(info.status, GRASessionStatus.active);
      final request = cloud.requests.single;
      expect(request.header('X-Linksys-Token'), 'agent-token');
      expect(request.header('Authorization'),
          'LinksysUserAuth session_token="agent-token"');
    });

    test('uses the stored token when it is given none', () async {
      cloud.answers('GET', '$_guardianSessions/G1', json: guardianSession);

      await repository.getSessionInfo(sessionId: 'G1');

      expect(cloud.requests.single.header('X-Linksys-Token'), 'stored-token');
    });
  });

  group('raGenPin', () {
    test('asks for a PIN for the session and returns it', () async {
      cloud.answers('POST', _raPin, json: {
        'remoteAssistanceSession': {
          'remoteAssistanceSessionId': 'S1',
          'pin': '010794',
          'status': 'PENDING',
        },
      });

      final pin = await repository.raGenPin(sessionId: 'S1', networkId: 'N1');

      expect(pin, '010794');
      final request = cloud.requests.single;
      expect(request.json, {
        'remoteAssistanceSession': {'remoteAssistanceSessionId': 'S1'},
      });
      expect(request.header('X-Linksys-Network-Id'), 'N1');
    });

    test('reports a session already in progress', () async {
      cloud.answersError('POST', _raPin, 'SESSION_IN_PROGRESS');

      await expectLater(
        repository.raGenPin(sessionId: 'S1', networkId: 'N1'),
        throwsA(isA<ErrorResponse>()
            .having((e) => e.code, 'code', 'SESSION_IN_PROGRESS')),
      );
    });
  });

  group('deleteSession', () {
    test('deletes the Guardian session with the stored token', () async {
      cloud.answers('DELETE', '$_guardianSessions/G1');

      await repository.deleteSession(sessionId: 'G1');

      final request = cloud.requests.single;
      expect(request.method, 'DELETE');
      expect(request.header('X-Linksys-Token'), 'stored-token');
    });

    test('reports the error the cloud answers with', () async {
      cloud.answersError(
          'DELETE', '$_guardianSessions/G1', 'SESSION_NOT_FOUND');

      await expectLater(repository.deleteSession(sessionId: 'G1'),
          throwsA(isA<ErrorResponse>()));
    });
  });

  group('testPingPng', () {
    const ping = '/cloud/ping.png/';

    test('is true when the cloud answers with its PNG', () async {
      cloud.answers('GET', ping, headers: {'content-type': 'image/png'});

      expect(await repository.testPingPng(), isTrue);
      expect(cloud.requests.single.url.queryParameters.keys, contains('ts'));
    });

    test('is false for an answer that is not the PNG', () async {
      cloud.answers('GET', ping, headers: {'content-type': 'text/html'});

      expect(await repository.testPingPng(), isFalse);
    });

    test('is false when the cloud cannot be reached', () async {
      cloud.fails('GET', ping, ClientException('Failed host lookup'));

      expect(await repository.testPingPng(), isFalse);
    });
  });
}
