// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

import 'package:linksys_app/core/jnap/models/lan_settings.dart';

enum SafeBrowsingType { off, fortinet, openDNS }

class SafeBrowsingState extends Equatable {
  final bool isLoading;
  final RouterLANSettings? lanSetting;
  final SafeBrowsingType safeBrowsingType;
  final bool hasFortinet;

  const SafeBrowsingState({
    this.isLoading = true,
    this.lanSetting,
    this.safeBrowsingType = SafeBrowsingType.off,
    this.hasFortinet = false,
  });

  SafeBrowsingState copyWith({
    bool? isLoading,
    RouterLANSettings? lanSetting,
    SafeBrowsingType? safeBrowsingType,
    bool? hasFortinet,
  }) {
    return SafeBrowsingState(
      isLoading: isLoading ?? this.isLoading,
      lanSetting: lanSetting ?? this.lanSetting,
      safeBrowsingType: safeBrowsingType ?? this.safeBrowsingType,
      hasFortinet: hasFortinet ?? this.hasFortinet,
    );
  }

  @override
  List<Object?> get props => [isLoading, lanSetting, safeBrowsingType, hasFortinet];
}
