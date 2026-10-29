import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// A Wi-Fi client on MLO, as DataElements reports it (#1686 item 2).
///
/// Built from a `STAMLD` with two or more `AffiliatedSTA` links under the node
/// that also lists the client's `BSS.STA` row. A client on MLO associates on
/// several bands at once, but its `BSS.STA` row and its Hosts row each name
/// only the one band it associated on, while that row's rates are the active
/// link's (measured on 2.0.3.26101482: the row said 2.4 GHz, its rates were
/// 5 GHz). So [bands] comes from the links, never from that row.
class MloClientInfo extends Equatable with DiagnosticLoggable {
  /// The bands of the client's links, one entry per band, in the order
  /// 2.4 GHz, 5 GHz, 6 GHz, spelled the way the app spells bands. A link whose
  /// band could not be resolved is left out.
  final List<String> bands;

  /// RSSI in dBm of the active link: the link that carries values.
  ///
  /// Null when no link does, which is normal for the first ~50 s after
  /// association (both links read 0); the client is still on MLO then, and
  /// the app shows its signal and rates empty rather than taking them from
  /// another source (#1686).
  final int? signalStrength;

  /// The active link's last rates in kbps, null where no link carries one.
  final int? downlinkRate;
  final int? uplinkRate;

  const MloClientInfo({
    required this.bands,
    this.signalStrength,
    this.downlinkRate,
    this.uplinkRate,
  });

  @override
  String get diagnosticName => 'MloClientInfo';

  @override
  Map<String, Object?> get namedProps => {
        'bands': bands,
        'signalStrength': signalStrength,
        'downlinkRate': downlinkRate,
        'uplinkRate': uplinkRate,
      };
}
