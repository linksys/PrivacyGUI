import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/model/app_signature.dart';
import 'package:linksys_moab/model/secure_profile.dart';
import 'package:linksys_moab/util/logger.dart';
import '../util/storage.dart';
import 'app_icon_manager.dart';
import '../model/cloud_preset.dart';
import '../model/web_filter.dart';

class SecurityProfileManager {
  factory SecurityProfileManager() {
    _singleton ??= SecurityProfileManager._();
    return _singleton!;
  }

  SecurityProfileManager._();

  static SecurityProfileManager? _singleton;

  static SecurityProfileManager instance() {
    return SecurityProfileManager();
  }

  List<CFSecureProfile> _securityProfiles = [];

  List<CFSecureProfile> get defaultSecurityProfiles => _securityProfiles;

  //
  Future<List<CFSecureProfile>> fetchDefaultPresets() async {
    // fetch App signature
    final appSignatures = await fetchAppSignature();
    await AppIconManager.instance().getAppIds();
    // fetch web filters
    final webFilters = await fetchWebFilters();
    logger.d('fetchDefaultPresets:: web filters count: ${webFilters.length}');
    // fetch security category presets
    final securityCategory = await fetchSecurityCategoryPresets();
    // fetch profile presets
    final profilePresets = await fetchProfilePresets();
    logger.d(
        'fetchDefaultPresets:: profile preset count: ${profilePresets.length}');
    final result = profilePresets.map((preset) {
      logger.d('fetchDefaultPresets:: profile preset: 1');

      final name = preset.name;
      final id = preset.identifier;
      logger.d('fetchDefaultPresets:: profile preset: $name, $id');
      // category rules
      final categories = preset.rules
          .map((cRule) {
            final categoryName = cRule.target;
            final categoryId = cRule.identifier;
            final categoryStatus = cRule.expression.value;
            // find
            logger.d('fetchDefaultPresets:: category id: $categoryId');
            final securityPreset = securityCategory.firstWhereOrNull(
                (element) => element.identifier == categoryId);
            if (securityPreset == null) {
              return null;
            }
            // handle web filters
            final webFilterList =
                _extractWebFilters(securityPreset, webFilters);
            final appSignatureList = _extractAppSignatures(securityPreset, appSignatures, categoryStatus);
            logger.d(
                'fetchDefaultPresets:: category: $categoryName, web filter count: ${webFilterList.length}, app signature count: ${appSignatureList.length}');
            final cfPreset = CFSecureCategory(
              name: categoryName,
              id: categoryId,
              status: CFSecureCategory.mapStatus(categoryStatus),
              description: '',
              webFilters: CFWebFilters(
                status: CFSecureCategory.mapStatus(categoryStatus),
                webFilters: webFilterList,
              ),
              apps: appSignatureList,
            );
            return cfPreset;
          })
          .whereType<CFSecureCategory>()
          .toList();
      return CFSecureProfile(
        id: id,
        name: name,
        description: '',
        securityCategories: categories,
      );
    }).toList();
    logger.d('fetch default security profiles done!\n $result');
    _securityProfiles = result;
    return result;
  }

  List<WebFilter> _extractWebFilters(
      MoabPreset securityPreset, List<WebFilter> webFilters) {
    return securityPreset.rules
        .where((element) => element.target == 'webfilter')
        .map((e) => webFilters.firstWhere((e2) => e2.id == e.expression.value))
        .toList();
  }

  List<CFAppSignature> _extractAppSignatures(MoabPreset securityPreset,
      List<AppSignature> appSignatures, String categoryStatus) {
    return securityPreset.rules
        .where((element) => element.target == 'application')
        .map((e) {
          final field =
              e.expression.field == 'applicationId' ? 'id' : e.expression.field; // use id instead the applicationId
          final value = e.expression.value;
          final rawApps = appSignatures
              .map((e) => e.toJson())
              .where((element) => element[field].toString().contains(value))
              .map((e) => AppSignature.fromJson(e))
              .toList();
          if (rawApps.isEmpty) {
            return null;
          }
          final name = e.expression.field == 'applicationId'
              ? rawApps.first.name
              : value;
          logger.d('raw apps: ${rawApps.length}');
          String appIcon;
          appIcon = rawApps
              .where((value) =>
          !AppIconManager.instance().isDefaultIcon(value.id))
              .firstOrNull?.id ?? '0';
          final cfAppSignature = CFAppSignature(
            name: name,
            icon: appIcon,
            category: rawApps.first.category,
            status: CFSecureCategory.mapStatus(categoryStatus),
            raw: rawApps,
          );
          logger.d(
              'raw apps: field - $field, value - $value, ${rawApps.length}, ${appIcon.length}');
          return cfAppSignature;
        })
        .whereType<CFAppSignature>()
        .toList();
  }

  Future<List<MoabPreset>> fetchProfilePresets() async {
    final file = File.fromUri(Storage.secureProfilePresetsFileUri);
    await _checkResourceExpiration(file, CloudResourceType.securityProfiles);
    final str = file.readAsStringSync();
    final jsonArray = List.from(jsonDecode(str));
    return List<MoabPreset>.from(jsonArray.map((e) => MoabPreset.fromJson(e)));
  }

  Future<List<MoabPreset>> fetchSecurityCategoryPresets() async {
    final file = File.fromUri(Storage.categoryPresetsFileUri);
    await _checkResourceExpiration(file, CloudResourceType.securityCategories);
    final str = file.readAsStringSync();
    final jsonArray = List.from(jsonDecode(str));
    return List<MoabPreset>.from(jsonArray.map((e) => MoabPreset.fromJson(e)));
  }

  Future<List<WebFilter>> fetchWebFilters() async {
    final file = File.fromUri(Storage.webFiltersFileUri);
    await _checkResourceExpiration(file, CloudResourceType.webFilters);
    final str = file.readAsStringSync();
    final jsonArray = List.from(jsonDecode(str));

    ///   Ignore this data
    ///   {
    ///     "id": "0",
    ///     "group": "Unrated",
    ///     "desc": "Sites not yet analyzed/categorized are considered unrated.",
    ///     "example": "",
    ///     "active": true,
    ///     "group_id": "21"
    ///   }
    ///
    return List<WebFilter>.from(jsonArray
        .where((e) => e['name'] != null)
        .map((e) => WebFilter.fromJson(e)));
  }

  Future<List<CloudAppSignature>> fetchAppSignature() async {
    final file = File.fromUri(Storage.appSignaturesFileUri);
    await _checkResourceExpiration(file, CloudResourceType.appSignature);
    final cJsonStr = file.readAsStringSync();
    // TODO get form FW
    final fwJsonStr = await rootBundle
        .loadString('assets/resources/fcn_application.name.json');

    final fwJsonArray = List.from(jsonDecode(fwJsonStr));

    final cloudJsonArray = List.from(jsonDecode(cJsonStr));

    final result = mappingAppSignature(fwJsonArray, cloudJsonArray);
    return result;
  }

  Future _checkResourceExpiration(File file, CloudResourceType type) async {
    if (!file.existsSync()) {
      await CloudEnvironmentManager().downloadResources(type);
    }
    final lastModified = file.lastModifiedSync();
    final diff = DateTime.now().millisecondsSinceEpoch -
        lastModified.millisecondsSinceEpoch;
    if (diff > resourceDownloadTimeThreshold[type]!) {
      logger.d('Resource expired! $diff, Download again - $type');
      await CloudEnvironmentManager().downloadResources(type);
    }
  }

//////
  static Color colorMapping(String id) {
    if (id == 'ADULT') {
      return MoabColor.contentFilterAdultPreset;
    } else if (id == 'CHILD') {
      return MoabColor.contentFilterChildPreset;
    } else if (id == 'TEEN') {
      return MoabColor.contentFilterTeenPreset;
    } else {
      return MoabColor.contentFilterChildPreset;
    }
  }
}
