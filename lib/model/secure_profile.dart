import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/model/app_signature.dart';
import 'package:linksys_moab/model/web_filter.dart';

import 'group_profile.dart';

mixin CFStatus {
  late final FilterStatus status;

  FilterStatus switchStatus() {
    if (status == FilterStatus.allowed) {
      return FilterStatus.notAllowed;
    } else if (status == FilterStatus.notAllowed) {
      return FilterStatus.allowed;
    } else {
      return status;
    }
  }

  static FilterStatus mapStatus(String status) {
    if (status == 'Block') {
      return FilterStatus.force;
    } else if (status == 'Allow') {
      return FilterStatus.allowed;
    } else if (status == 'NotAllow') {
      return FilterStatus.notAllowed;
    } else {
      return FilterStatus.notAllowed;
    }
  }

  bool isNotAllowed() {
    return status != FilterStatus.allowed;
  }
}

class CFSecureProfile extends Equatable {
  const CFSecureProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.securityCategories,
  });

  CFSecureProfile copyWith({
    String? id,
    String? name,
    String? description,
    Color? color,
    List<CFSecureCategory>? securityCategories,
  }) {
    return CFSecureProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      securityCategories: securityCategories ?? this.securityCategories,
    );
  }

  final String id;
  final String name;
  final String description;
  final List<CFSecureCategory> securityCategories;

  @override
  List<Object?> get props => [id, name, description, securityCategories];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'securityCategories': securityCategories.map((e) => e.toJson()).toList(),
    };
  }

  factory CFSecureProfile.fromJson(Map<String, dynamic> json) {
    return CFSecureProfile(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      securityCategories: List.from(json['securityCategories'])
          .map((e) => CFSecureCategory.fromJson(e))
          .toList(),
    );
  }
}

class CFSecureCategory extends Equatable with CFStatus {
  static const searchCategoryId = 'SEARCH_CATEGORY';

  CFSecureCategory({
    required this.name,
    required this.id,
    required FilterStatus status,
    required this.description,
    required this.webFilters,
    required this.apps,
  }) {
    this.status = status;
  }

  factory CFSecureCategory.searchCategory() {
    return CFSecureCategory(
      name: '',
      id: searchCategoryId,
      status: FilterStatus.notAllowed,
      description: '',
      webFilters: CFWebFilters(
        status: FilterStatus.notAllowed,
        webFilters: [],
      ),
      apps: [],
    );
  }

  final String name;
  final String id;
  final String description;
  final CFWebFilters webFilters;
  final List<CFAppSignature> apps;

  CFSecureCategory copyWith({
    String? name,
    String? id,
    FilterStatus? status,
    String? description,
    CFWebFilters? webFilters,
    List<CFAppSignature>? apps,
  }) {
    return CFSecureCategory(
      name: name ?? this.name,
      id: id ?? this.id,
      status: status ?? this.status,
      description: description ?? this.description,
      webFilters: webFilters ?? this.webFilters,
      apps: apps ?? this.apps,
    );
  }

  getAppSummaryStatus() {
    if (apps.isEmpty) {
      return FilterStatus.notAllowed;
    }
    if (status == FilterStatus.force) {
      return FilterStatus.force;
    }
    return apps.fold<FilterStatus>(
        apps[0].status == FilterStatus.force
            ? FilterStatus.notAllowed
            : apps[0].status,
        (value, element) =>
            (element.status != FilterStatus.force && value != element.status)
                ? FilterStatus.someAllowed
                : value);
  }

  AppSignature? getRawAppById(String appId) {
    return getAppById(appId)?.raw.firstWhereOrNull((raw) => raw.id == appId);
  }

  CFAppSignature? getAppById(String appId) {
    return apps
        .firstWhereOrNull((app) => app.raw.any((raw) => raw.id == appId));
  }

  @override
  List<Object?> get props => [name, id, status, description, webFilters, apps];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'status': status.name,
      'description': description,
      'webFilters': webFilters.toJson(),
      'apps': apps.map((e) => e.toJson()).toList(),
    };
  }

  factory CFSecureCategory.fromJson(Map<String, dynamic> json) {
    return CFSecureCategory(
      name: json['name'],
      id: json['id'],
      status: FilterStatus.values
              .firstWhereOrNull((element) => element.name == json['status']) ??
          FilterStatus.allowed,
      description: json['description'],
      webFilters: CFWebFilters.fromJson(json['webFilters']),
      apps: List.from(json['apps'])
          .map((e) => CFAppSignature.fromJson(e))
          .toList(),
    );
  }
}

class CFWebFilters extends Equatable with CFStatus {
  CFWebFilters({
    required FilterStatus status,
    required this.webFilters,
  }) {
    this.status = status;
  }

  final List<WebFilter> webFilters;

  CFWebFilters copyWith({FilterStatus? status, List<WebFilter>? webFilters}) {
    return CFWebFilters(
      status: status ?? this.status,
      webFilters: webFilters ?? this.webFilters,
    );
  }

  @override
  List<Object?> get props => [status, webFilters];

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'webFilters': webFilters.map((e) => e.toJson()).toList(),
    };
  }

  factory CFWebFilters.fromJson(Map<String, dynamic> json) {
    return CFWebFilters(
      status: FilterStatus.values
              .firstWhereOrNull((element) => element.name == json['status']) ??
          FilterStatus.allowed,
      webFilters: List.from(json['webFilters'])
          .map((e) => WebFilter.fromJson(e))
          .toList(),
    );
  }
}

class CFAppSignature extends Equatable with CFStatus {
  CFAppSignature({
    required this.name,
    required this.category,
    this.icon = '0',
    required FilterStatus status,
    this.raw = const [],
  }) {
    this.status = status;
  }

  final String name;
  final String category;
  final String icon;
  final List<AppSignature> raw;

  CFAppSignature copyWith({
    String? name,
    String? category,
    String? icon,
    FilterStatus? status,
    List<AppSignature>? raw,
  }) {
    return CFAppSignature(
      name: name ?? this.name,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      raw: raw ?? this.raw,
    );
  }

  @override
  List<Object?> get props => [name, category, icon, status, raw];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'icon': icon,
      'status': status.name,
      'raw': raw.map((e) => e.toJson()).toList(),
    };
  }

  factory CFAppSignature.fromJson(Map<String, dynamic> json) {
    return CFAppSignature(
      name: json['name'],
      category: json['category'],
      icon: json['icon'],
      status: FilterStatus.values
              .firstWhereOrNull((element) => element.name == json['status']) ??
          FilterStatus.allowed,
      raw: List.from(json['raw']).map((e) => AppSignature.fromJson(e)).toList(),
    );
  }
}
