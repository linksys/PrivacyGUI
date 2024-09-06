const signalThresholdSNR = [40, 25, 10];
const signalThresholdRSSI = [-65, -71, -78];

enum NodeSignalLevel {
  wired(displayTitle: 'Wired'),
  none(displayTitle: 'No signal'),
  poor(displayTitle: 'Weak'),
  good(displayTitle: 'Good'),
  fair(displayTitle: 'Fair'),
  excellent(displayTitle: 'Excellent');

  const NodeSignalLevel({
    required this.displayTitle,
  });

  final String displayTitle;
}

NodeSignalLevel getWifiSignalLevel(int? signalStrength) {
  if (signalStrength == null) {
    return NodeSignalLevel.wired;
  }
  var signalThreshold =
      signalStrength > 0 ? signalThresholdSNR : signalThresholdRSSI;
  var index = signalThreshold.indexWhere((element) => signalStrength > element);
  if (index == -1) {
    return NodeSignalLevel.poor;
  } else {
    switch (3 - index) {
      case 3:
        return NodeSignalLevel.excellent;
      case 2:
        return NodeSignalLevel.good;
      case 1:
        return NodeSignalLevel.fair;
      default:
        return NodeSignalLevel.poor;
    }
  }
}
