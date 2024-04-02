import 'dart:convert';

import 'package:linksys_app/core/http/linksys_http_client.dart';
import 'package:linksys_app/core/cloud/model/cloud_session_model.dart';
import 'package:linksys_app/core/cloud/model/error_response.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

import 'linksys_cloud_repository_test.mocks.dart';

@GenerateNiceMocks(
    [MockSpec<LinksysHttpClient>(onMissingStub: OnMissingStub.returnDefault)])
void main() {
  group('linksys cloud repository - login', () {
    test('login success with session token', () async {
      final mockHttpClient = MockLinksysHttpClient();
      when(mockHttpClient.post(any,
              body: anyNamed('body'), headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
              '{"access_token":"9F228633C885491BB2141BCE639684D5951A8581AE934FC589B25FB6F3524CFF","token_type":"Bearer","expires_in":86400,"refresh_token":"3CB472364DD148BBB4A267D54DD0DC89FC51A2186E8B4E97878537EDC31F281B"}',
              200));
      final container = ProviderContainer(overrides: [
        cloudRepositoryProvider.overrideWithValue(
            LinksysCloudRepository(httpClient: mockHttpClient))
      ]);

      final result = await container
          .read(cloudRepositoryProvider)
          .login(username: 'username', password: 'password');

      expect(result, isA<SessionToken>());
    });
    test('login failed with wrong password', () async {
      final mockHttpClient = MockLinksysHttpClient();
      when(mockHttpClient.post(any,
              body: anyNamed('body'), headers: anyNamed('headers')))
          .thenThrow(http.Response(
              '{"error":"invalid_credentials","error_description":"Invalid credentials"}',
              400));
      final container = ProviderContainer(overrides: [
        cloudRepositoryProvider.overrideWithValue(
            LinksysCloudRepository(httpClient: mockHttpClient))
      ]);

      expect(
          () async => await container
              .read(cloudRepositoryProvider)
              .login(username: 'username', password: 'password'),
          throwsA(isA<http.Response>()));
      try {
        await container
            .read(cloudRepositoryProvider)
            .login(username: 'username', password: 'password')
            .onError((error, stackTrace) {
          final resp = error as http.Response;
          throw ErrorResponse.fromJson(resp.statusCode, json.decode(resp.body));
        });
      } catch (error) {
        expect(error, isA<ErrorResponse>());
      }
    });
  });
}

///
///
///
