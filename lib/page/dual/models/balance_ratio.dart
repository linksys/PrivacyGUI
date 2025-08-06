
enum DualWANBalanceRatio {
  equalDistribution,
  favorPrimaryWAN;

  String toDisplayString(context) {
    return switch (this) {
      DualWANBalanceRatio.equalDistribution => '1:1 - Eaual distribution (Default)',
      DualWANBalanceRatio.favorPrimaryWAN => '4:1 - Favor primary WAN',
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