import 'dart:convert';

import 'package:linksys_moab/constants/fcn_const.dart';
import 'package:linksys_moab/model/fcn/address_group.dart';
import 'package:linksys_moab/model/fcn/application_list.dart';
import 'package:linksys_moab/model/fcn/policy.dart';
import 'package:linksys_moab/model/fcn/web_filter_profile.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension BluetoothService on RouterRepository {
  Future<JnapSuccess> requestFOSContainer(
      String uri, String method, String? data) async {
    final command = createCommand(JNAPAction.requestFOSContainer.actionValue,
        data: {
          'uri': uri,
          'method': method,
          'data': data,
        }..removeWhere((key, value) => value == null));

    final result = await command.publish(mqttClient!);
    return handleJnapResult(result.body);
  }

  Future<JnapSuccess> getRequestFOSContainer(String uri, {String? data}) async {
    return requestFOSContainer(uri, "GET", data);
  }

  Future<JnapSuccess> postRequestFOSContainer(String uri,
      {String? data}) async {
    return requestFOSContainer(uri, "POST", data);
  }

  Future<JnapSuccess> putRequestFOSContainer(String uri, {String? data}) async {
    return requestFOSContainer(uri, "PUT", data);
  }

  Future<JnapSuccess> deleteRequestFOSContainer(String uri, {String? data}) async {
    return requestFOSContainer(uri, "DELETE", data);
  }

  // log/custom-field
  Future<JnapSuccess> setLogCustomField(String id, String name, String value) {
    return postRequestFOSContainer('$fcnBaseUri$fcnLogCustomFieldPath',
        data: jsonEncode({"id": id, "name": name, "value": value}));
  }

  // firewall/policy
  Future<JnapSuccess> setFirewallPolicy(FCNPolicy policy) {
    return postRequestFOSContainer('$fcnBaseUri$fcnFirewallPolicyPath',
        data: jsonEncode(policy.toFullJson()));
  }
  Future<JnapSuccess> getFirewallPolicies() {
    return getRequestFOSContainer('$fcnBaseUri$fcnFirewallPolicyPath',);
  }
  Future<JnapSuccess> getFirewallPolicyById(String id) {
    return getRequestFOSContainer('$fcnBaseUri$fcnFirewallPolicyPath/$id',);
  }
  Future<JnapSuccess> deleteFirewallPolicyById(String id) {
    return deleteRequestFOSContainer('$fcnBaseUri$fcnFirewallPolicyPath/$id',);
  }

  // webfilter/profile
  Future<JnapSuccess> setWebFilterProfile(FCNWebFilterProfile webFilterProfile) {
    return postRequestFOSContainer('$fcnBaseUri$fcnWebfilterProfilePath',
        data: jsonEncode(webFilterProfile.toFullJson()));
  }
  Future<JnapSuccess> getWebFilterProfiles() {
    return getRequestFOSContainer('$fcnBaseUri$fcnWebfilterProfilePath',);
  }
  Future<JnapSuccess> getWebFilterProfileByName(String name) {
    return getRequestFOSContainer('$fcnBaseUri$fcnWebfilterProfilePath/$name',);
  }
  Future<JnapSuccess> deleteWebFilterProfileByName(String name) {
    return deleteRequestFOSContainer('$fcnBaseUri$fcnWebfilterProfilePath/$name',);
  }

  // application/list
  Future<JnapSuccess> setApplicationList(FCNApplicationList applicationList) {
    return postRequestFOSContainer('$fcnBaseUri$fcnApplicationListPath',
        data: jsonEncode(applicationList.toFullJson()));
  }
  Future<JnapSuccess> getApplicationList() {
    return getRequestFOSContainer('$fcnBaseUri$fcnApplicationListPath',);
  }
  Future<JnapSuccess> getApplicationListByName(String name) {
    return getRequestFOSContainer('$fcnBaseUri$fcnApplicationListPath/$name',);
  }
  Future<JnapSuccess> deleteApplicationListByName(String name) {
    return deleteRequestFOSContainer('$fcnBaseUri$fcnApplicationListPath/$name',);
  }

  // application/name
  Future<JnapSuccess> getApplicationName() {
    return getRequestFOSContainer('$fcnBaseUri$fcnApplicationNamePath',);
  }

  // firewall/addrgrp
  Future<JnapSuccess> setFirewallAddrgrp(FCNAddressGroup addressGroup) {
    return postRequestFOSContainer('$fcnBaseUri$fcnFirewallAddrgrpPath',
        data: jsonEncode(addressGroup.toJson()));
  }
  Future<JnapSuccess> getFirewallAddrgrp() {
    return getRequestFOSContainer('$fcnBaseUri$fcnFirewallAddrgrpPath',);
  }
  Future<JnapSuccess> getFirewallAddrgrpByName(String name) {
    return getRequestFOSContainer('$fcnBaseUri$fcnFirewallAddrgrpPath/$name',);
  }
  Future<JnapSuccess> deleteFirewallAddrgrpByName(String name) {
    return deleteRequestFOSContainer('$fcnBaseUri$fcnFirewallAddrgrpPath/$name',);
  }
}
