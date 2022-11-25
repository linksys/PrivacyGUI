import 'dart:convert';

import 'package:linksys_moab/constants/fcn_const.dart';
import 'package:linksys_moab/model/fcn/address_group.dart';
import 'package:linksys_moab/model/fcn/application_list.dart';
import 'package:linksys_moab/model/fcn/policy.dart';
import 'package:linksys_moab/model/fcn/web_filter_profile.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension FCNService on RouterRepository {
  @Deprecated('Not for now')
  Future<JNAPSuccess> requestFOSContainer(
      String uri, String method, String? data) async {
    final command = createCommand(JNAPAction.requestFOSContainer.actionValue,
        data: {
          'uri': uri,
          'method': method,
          'data': data,
        }..removeWhere((key, value) => value == null));

    final result = await command.publish(executor!);
    return handleJNAPResult(result);
  }

  Future<JNAPSuccess> getRequestFOSContainer(String uri, {String? data}) async {
    return requestFOSContainer(uri, "GET", data);
  }

  Future<JNAPSuccess> postRequestFOSContainer(String uri,
      {String? data}) async {
    return requestFOSContainer(uri, "POST", data);
  }

  Future<JNAPSuccess> putRequestFOSContainer(String uri, {String? data}) async {
    return requestFOSContainer(uri, "PUT", data);
  }

  Future<JNAPSuccess> deleteRequestFOSContainer(String uri, {String? data}) async {
    return requestFOSContainer(uri, "DELETE", data);
  }

  // log/custom-field
  Future<JNAPSuccess> setLogCustomField(String id, String name, String value) {
    return postRequestFOSContainer('$fcnBaseUri$fcnLogCustomFieldPath',
        data: jsonEncode({"id": id, "name": name, "value": value}));
  }

  // firewall/policy
  Future<JNAPSuccess> setFirewallPolicy(FCNPolicy policy) {
    return postRequestFOSContainer('$fcnBaseUri$fcnFirewallPolicyPath',
        data: jsonEncode(policy.toFullJson()));
  }
  Future<JNAPSuccess> getFirewallPolicies() {
    return getRequestFOSContainer('$fcnBaseUri$fcnFirewallPolicyPath',);
  }
  Future<JNAPSuccess> getFirewallPolicyById(String id) {
    return getRequestFOSContainer('$fcnBaseUri$fcnFirewallPolicyPath/$id',);
  }
  Future<JNAPSuccess> deleteFirewallPolicyById(String id) {
    return deleteRequestFOSContainer('$fcnBaseUri$fcnFirewallPolicyPath/$id',);
  }

  // webfilter/profile
  Future<JNAPSuccess> setWebFilterProfile(FCNWebFilterProfile webFilterProfile) {
    return postRequestFOSContainer('$fcnBaseUri$fcnWebfilterProfilePath',
        data: jsonEncode(webFilterProfile.toFullJson()));
  }
  Future<JNAPSuccess> getWebFilterProfiles() {
    return getRequestFOSContainer('$fcnBaseUri$fcnWebfilterProfilePath',);
  }
  Future<JNAPSuccess> getWebFilterProfileByName(String name) {
    return getRequestFOSContainer('$fcnBaseUri$fcnWebfilterProfilePath/$name',);
  }
  Future<JNAPSuccess> deleteWebFilterProfileByName(String name) {
    return deleteRequestFOSContainer('$fcnBaseUri$fcnWebfilterProfilePath/$name',);
  }

  // application/list
  Future<JNAPSuccess> setApplicationList(FCNApplicationList applicationList) {
    return postRequestFOSContainer('$fcnBaseUri$fcnApplicationListPath',
        data: jsonEncode(applicationList.toFullJson()));
  }
  Future<JNAPSuccess> getApplicationList() {
    return getRequestFOSContainer('$fcnBaseUri$fcnApplicationListPath',);
  }
  Future<JNAPSuccess> getApplicationListByName(String name) {
    return getRequestFOSContainer('$fcnBaseUri$fcnApplicationListPath/$name',);
  }
  Future<JNAPSuccess> deleteApplicationListByName(String name) {
    return deleteRequestFOSContainer('$fcnBaseUri$fcnApplicationListPath/$name',);
  }

  // application/name
  Future<JNAPSuccess> getApplicationName() {
    return getRequestFOSContainer('$fcnBaseUri$fcnApplicationNamePath',);
  }

  // firewall/addrgrp
  Future<JNAPSuccess> setFirewallAddrgrp(FCNAddressGroup addressGroup) {
    return postRequestFOSContainer('$fcnBaseUri$fcnFirewallAddrgrpPath',
        data: jsonEncode(addressGroup.toJson()));
  }
  Future<JNAPSuccess> getFirewallAddrgrp() {
    return getRequestFOSContainer('$fcnBaseUri$fcnFirewallAddrgrpPath',);
  }
  Future<JNAPSuccess> getFirewallAddrgrpByName(String name) {
    return getRequestFOSContainer('$fcnBaseUri$fcnFirewallAddrgrpPath/$name',);
  }
  Future<JNAPSuccess> deleteFirewallAddrgrpByName(String name) {
    return deleteRequestFOSContainer('$fcnBaseUri$fcnFirewallAddrgrpPath/$name',);
  }
}
