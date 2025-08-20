
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

  static DualWANBalanceRatio fromValue(String value) {
    return DualWANBalanceRatio.values
        .firstWhere((e) => e.name == value, orElse: () => DualWANBalanceRatio.equalDistribution);
  }

  String toValue() {
    return switch (this) {
      DualWANBalanceRatio.equalDistribution => 'equalDistribution',
      DualWANBalanceRatio.favorPrimaryWAN => 'favorPrimaryWAN',
    };
  }
} 