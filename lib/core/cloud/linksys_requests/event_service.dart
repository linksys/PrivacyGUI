import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:linksys_app/core/cloud/model/cloud_event_action.dart';
import 'package:linksys_app/core/cloud/model/cloud_event_subscription.dart';
import 'package:linksys_app/core/http/linksys_http_client.dart';

import '../../../constants/_constants.dart';

extension EventService on LinksysHttpClient {
  Future<Response> queryEventSubscription(
    String token,
    String networkId,
  ) {
    final endpoint = combineUrl(kEventeSubscriptionCreate, args: {
      kVarNetworkId: networkId,
    });
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);

    return get(Uri.parse(endpoint), headers: header);
  }

  Future<Response> createNetworkEventSubscription(
    String token,
    String networkId,
    CloudEventSubscription cloudEventSubscription,
  ) async {
    final endpoint = combineUrl(kEventeSubscriptionCreate, args: {
      kVarNetworkId: networkId,
    });
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);
    final body = {
      'eventSubscription': cloudEventSubscription.toMap()
        ..removeWhere((key, value) => value == null)
    };
    return this
        .post(Uri.parse(endpoint), headers: header, body: jsonEncode(body));
  }

  Future<Response> getNetworkEventAction(String token, eventSubscriptionId) {
    final endpoint = combineUrl(kEventNetworkActionCreate, args: {
      kVarEventSubscriptionId: eventSubscriptionId,
    });
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);
    return this.get(
      Uri.parse(endpoint),
      headers: header,
    );
  }

  Future<Response> deleteNetworkEventAction(String token, eventSubscriptionId) {
    final endpoint = combineUrl(kEventNetworkActionCreate, args: {
      kVarEventSubscriptionId: eventSubscriptionId,
    });
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);
    return this.delete(
      Uri.parse(endpoint),
      headers: header,
    );
  }

  Future<Response> createNetworkEventAction(
    String token,
    String eventSubscriptionId,
    CloudEventAction cloudEventAction,
  ) {
    final endpoint = combineUrl(kEventNetworkActionCreate, args: {
      kVarEventSubscriptionId: eventSubscriptionId,
    });
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);

    final body = {
      'eventActions': {
        'eventAction': [cloudEventAction.toMap()],
        'eventSubscriptionId': eventSubscriptionId,
      },
    };
    return this
        .post(Uri.parse(endpoint), headers: header, body: jsonEncode(body));
  }
}
