import 'dart:convert';

import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

import '../mocks/linksys_http_client_mocks.dart';

void main() {
  group('linksys cloud repository - login', () {
    test('login success with session token', () async {
      final mockHttpClient = MockLinksysHttpClient();
      when(mockHttpClient.post(any,
              body: anyNamed('body'), headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
              '{"access_token":"0000000000000000000000000000000000000000000000000000000000000003","token_type":"Bearer","expires_in":86400,"refresh_token":"0000000000000000000000000000000000000000000000000000000000000004"}',
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
