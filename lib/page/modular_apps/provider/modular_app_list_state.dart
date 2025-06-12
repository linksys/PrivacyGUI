// create a state class for modular app list
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/modular_apps/models/modular_app_data.dart';
import 'package:privacy_gui/page/modular_apps/models/modular_app_type.dart';

class ModularAppListState extends Equatable {
  final List<ModularAppData> apps;
  final String version;
  final int? lastUpdated;
  const ModularAppListState(
      {this.apps = const [], this.version = '', this.lastUpdated});

  List<ModularAppData> get defaultApps =>
      apps.where((app) => app.type == ModularAppType.app).toList();

  List<ModularAppData> get userApps =>
      apps.where((app) => app.type == ModularAppType.user).toList();

  List<ModularAppData> get premiumApps =>
      apps.where((app) => app.type == ModularAppType.premium).toList();

  ModularAppListState copyWith({
    List<ModularAppData>? apps,
    String? version,
    int? lastUpdated,
  }) {
    return ModularAppListState(
      apps: apps ?? this.apps,
      version: version ?? this.version,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory ModularAppListState.fromMap(Map<String, dynamic> map) {
    return ModularAppListState(
      apps: map['apps'].map((x) => ModularAppData.fromMap(x)).toList(),
      version: map['version'],
      lastUpdated: map['lastUpdated'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'apps': apps,
      'version': version,
      'lastUpdated': lastUpdated,
    };
  }

  factory ModularAppListState.fromJson(String source) =>
      ModularAppListState.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  @override
  List<Object?> get props => [apps, version, lastUpdated];
}