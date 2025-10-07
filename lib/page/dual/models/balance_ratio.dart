
import 'package:privacy_gui/core/jnap/models/dual_wan_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

enum DualWANBalanceRatio {
  equalDistribution,
  favorPrimaryWAN;

  String toDisplayString(context) {
    return switch (this) {
      DualWANBalanceRatio.equalDistribution => loc(context).dualWanBalanceRatioEqual,
      DualWANBalanceRatio.favorPrimaryWAN => loc(context).dualWanBalanceRatioFavorPrimary,
    };
  }

  static DualWANBalanceRatio fromValue(DualWANRatioData value) {
    return DualWANBalanceRatio.values
        .firstWhere((e) => e.name == value.name, orElse: () => DualWANBalanceRatio.equalDistribution);
  }

  String toValue() {
    return switch (this) {
      DualWANBalanceRatio.equalDistribution => '1-1',
      DualWANBalanceRatio.favorPrimaryWAN => '4-1',
    };
  }
} 