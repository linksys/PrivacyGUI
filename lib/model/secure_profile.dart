import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/model/app_signature.dart';
import 'package:linksys_moab/model/web_filter.dart';


import 'group_profile.dart';

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
}

class CFSecureCategory extends Equatable {
  static const searchCategoryId = 'SEARCH_CATEGORY';

  const CFSecureCategory({
    required this.name,
    required this.id,
    required this.status,
    required this.description,
    required this.webFilters,
    required this.apps,
  });

  factory CFSecureCategory.searchCategory() {
    return const CFSecureCategory(
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
  final FilterStatus status;
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

  static FilterStatus switchStatus(FilterStatus current) {
    if (current == FilterStatus.allowed) {
      return FilterStatus.notAllowed;
    } else if (current == FilterStatus.notAllowed) {
      return FilterStatus.allowed;
    } else {
      return current;
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

  @override
  List<Object?> get props => [name, id, status, description, webFilters, apps];
}

class CFWebFilters extends Equatable {
  const CFWebFilters({
    required this.status,
    required this.webFilters,
  });

  final FilterStatus status;
  final List<WebFilter> webFilters;

  CFWebFilters copyWith({FilterStatus? status, List<WebFilter>? webFilters}) {
    return CFWebFilters(
      status: status ?? this.status,
      webFilters: webFilters ?? this.webFilters,
    );
  }

  @override
  List<Object?> get props => [status, webFilters];
}

class CFAppSignature extends Equatable {
  const CFAppSignature({
    required this.name,
    required this.category,
    this.icon = '0',
    required this.status,
    this.raw = const [],
  });

  final String name;
  final String category;
  final String icon;
  final FilterStatus status;
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
}