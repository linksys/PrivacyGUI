import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';

import '../../common/cloud_boundary.dart';

// Remote assistance on the cloud: the Guardian sessions a support agent opens,
// and the cloud ping. The account-side sessions and their PIN went with the
// support page that used them (#1849).

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
