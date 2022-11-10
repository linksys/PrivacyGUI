import 'package:equatable/equatable.dart';

import 'web_filter.dart';

///
/// {
///     "name": "default",
///     "comment": "Default web filtering.",
///     "replacemsg-group": "",
///     "options": "",
///     "https-replacemsg": "enable",
///     "post-action": "normal",
///     "override": {
///       "ovrd-cookie": "deny",
///       "ovrd-scope": "user",
///       "profile-type": "list",
///       "ovrd-dur-mode": "constant",
///       "ovrd-dur": "15m",
///       "profile-attribute": "Login-LAT-Service",
///       "ovrd-user-group": [],
///       "profile": []
///     },
///     "web": {
///       "bword-threshold": "10",
///       "bword-table": "0",
///       "urlfilter-table": "0",
///       "content-header-list": "0",
///       "blocklist": "disable",
///       "allowlist": ""
///     },
///     "ftgd-wf": {
///       "options": "",
///       "exempt-quota": "g21",
///       "ovrd": "",
///       "filters": [
///         ...
///       ],
///       "quota": [],
///       "max-quota-timeout": "300",
///       "rate-javascript-urls": "enable",
///       "rate-css-urls": "enable",
///       "rate-crl-urls": "enable"
///     },
///     "log-all-url": "disable",
///     "web-content-log": "enable",
///     "web-filter-command-block-log": "enable",
///     "web-filter-cookie-log": "enable",
///     "web-url-log": "enable",
///     "web-invalid-domain-log": "enable",
///     "web-ftgd-err-log": "enable",
///     "web-ftgd-quota-usage": "enable",
///     "extended-log": "disable"
///   }
///
class FCNWebFilterProfile extends Equatable {
  final String name;
  final List<FCNWebFilter> filters;

  @override
  List<Object?> get props => [name, filters];

  const FCNWebFilterProfile({
    required this.name,
    required this.filters,
  });

  FCNWebFilterProfile copyWith({
    String? name,
    List<FCNWebFilter>? filters,
  }) {
    return FCNWebFilterProfile(
      name: name ?? this.name,
      filters: filters ?? this.filters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'filters': filters.map((e) => e.toJson()).toList(),
    };
  }

  factory FCNWebFilterProfile.fromMap(Map<String, dynamic> map) {
    return FCNWebFilterProfile(
      name: map['name'],
      filters: List.from(map['filters'])
          .map((e) => FCNWebFilter.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toFullJson() {
    return {
      "name": name,
      "comment": "Default web filtering.",
      "replacemsg-group": "",
      "options": "",
      "https-replacemsg": "enable",
      "post-action": "normal",
      "override": {
        "ovrd-cookie": "deny",
        "ovrd-scope": "user",
        "profile-type": "list",
        "ovrd-dur-mode": "constant",
        "ovrd-dur": "15m",
        "profile-attribute": "Login-LAT-Service",
        "ovrd-user-group": [],
        "profile": []
      },
      "web": {
        "bword-threshold": "10",
        "bword-table": "0",
        "urlfilter-table": "0",
        "content-header-list": "0",
        "blocklist": "disable",
        "allowlist": ""
      },
      "ftgd-wf": {
        "options": "",
        "exempt-quota": "g21",
        "ovrd": "",
        "filters": [
          ...filters.map((e) => e.toJson()).toList(),
        ],
        "quota": [],
        "max-quota-timeout": "300",
        "rate-javascript-urls": "enable",
        "rate-css-urls": "enable",
        "rate-crl-urls": "enable"
      },
      "log-all-url": "disable",
      "web-content-log": "enable",
      "web-filter-command-block-log": "enable",
      "web-filter-cookie-log": "enable",
      "web-url-log": "enable",
      "web-invalid-domain-log": "enable",
      "web-ftgd-err-log": "enable",
      "web-ftgd-quota-usage": "enable",
      "extended-log": "disable"
    };
  }
}
