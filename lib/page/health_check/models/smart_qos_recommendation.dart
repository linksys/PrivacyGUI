import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/health_check_result.dart';

/// Shaping mode CAKE runs in.
///
/// [uploadOnly] shapes egress only and leaves ingress unlimited — correct when
/// download is fast enough that shaping it costs throughput for no latency win.
/// [both] shapes egress and ingress.
enum SmartQosMode { uploadOnly, both }

/// Smart QoS shaping values derived from a completed speed test.
///
/// ⚠️ THIS IS A CLIENT-SIDE MIRROR OF ROUTER LOGIC — TEMPORARY BY DESIGN.
///
/// The router is the authority on what it will shape to. This class duplicates
/// that arithmetic across a network boundary so the UI can show a preview
/// without a round-trip, because the app currently has no transport that can
/// reach the QoS endpoint (it speaks USP/TR-181 and JNAP; the QoS shaping
/// backend is a JNAP-style CGI that this firmware does not yet expose).
/// **Delete this class the moment a real transport lands** and read the values
/// from the router instead.
///
/// The duplication carries a real risk: if the firmware's recommendation math
/// changes, this copy goes stale silently and the UI will confidently display
/// values the router will not apply. Nothing in the system can detect that
/// divergence — which is why the UI labels these values as an estimate.
///
/// Mirrors `backend/smartqos.cgi` → `GetSmartQoSRecommendation` as of
/// 2026-08-19 (OpenWrt 23.05-SNAPSHOT, IPQ5332). Validated against one real
/// measurement: 347337/7464 kbps → 6717/312603/UploadOnly, matching what the
/// router committed to `/etc/config/smartqos`.
///
/// Known-unvalidated boundaries — confirm against the firmware before relying
/// on these for a config write:
/// - whether the 90% factor is applied before or after overhead subtraction
/// - whether the 200000 threshold is on download only (assumed), or upload/sum
/// - truncation vs rounding (integer division is assumed, matching shell `$(( ))`)
/// - whether a minimum clamp or gigabit-class cap exists
/// - whether overhead varies by WAN type (PPPoE/DSL vs fibre) rather than being 18
class SmartQosRecommendation extends Equatable {
  /// Shape to this fraction of measured bandwidth. Headroom is what actually
  /// lets CAKE control the queue — shaping at 100% hands the bottleneck back to
  /// the ISP's own buffer, which is the thing causing the lag.
  static const int shapingPercent = 90;

  /// Above this measured download, shaping ingress costs more than it gains.
  static const int uploadOnlyThresholdKbps = 200000;

  /// Per-packet framing overhead assumed when none is known.
  static const int defaultOverheadBytes = 18;

  final int uploadKbps;
  final int downloadKbps;
  final SmartQosMode mode;
  final int overheadBytes;
  final double measuredDownloadMbps;
  final double measuredUploadMbps;
  final int? latencyMs;

  const SmartQosRecommendation({
    required this.uploadKbps,
    required this.downloadKbps,
    required this.mode,
    this.overheadBytes = defaultOverheadBytes,
    this.measuredDownloadMbps = 0,
    this.measuredUploadMbps = 0,
    this.latencyMs,
  });

  /// Derive shaping values from a finished speed test.
  ///
  /// The JNAP [SpeedTestResult] already reports bandwidth in kbps (the rest of
  /// the health-check UI divides by 1000 to display Mbps), and latency in whole
  /// milliseconds, so no unit conversion is needed before scaling.
  factory SmartQosRecommendation.fromResult(SpeedTestResult result) {
    final downloadKbpsMeasured = result.downloadBandwidth ?? 0;
    final uploadKbpsMeasured = result.uploadBandwidth ?? 0;

    return SmartQosRecommendation(
      uploadKbps: uploadKbpsMeasured * shapingPercent ~/ 100,
      downloadKbps: downloadKbpsMeasured * shapingPercent ~/ 100,
      mode: downloadKbpsMeasured > uploadOnlyThresholdKbps
          ? SmartQosMode.uploadOnly
          : SmartQosMode.both,
      measuredDownloadMbps: downloadKbpsMeasured / 1000,
      measuredUploadMbps: uploadKbpsMeasured / 1000,
      latencyMs: result.latency,
    );
  }

  /// True when download is left unshaped, which the UI shows as "No limit needed".
  bool get isDownloadUnlimited => mode == SmartQosMode.uploadOnly;

  double get uploadMbps => uploadKbps / 1000;
  double get downloadMbps => downloadKbps / 1000;

  SmartQosRecommendation copyWith({
    int? uploadKbps,
    int? downloadKbps,
    SmartQosMode? mode,
    int? overheadBytes,
    double? measuredDownloadMbps,
    double? measuredUploadMbps,
    int? latencyMs,
  }) {
    return SmartQosRecommendation(
      uploadKbps: uploadKbps ?? this.uploadKbps,
      downloadKbps: downloadKbps ?? this.downloadKbps,
      mode: mode ?? this.mode,
      overheadBytes: overheadBytes ?? this.overheadBytes,
      measuredDownloadMbps: measuredDownloadMbps ?? this.measuredDownloadMbps,
      measuredUploadMbps: measuredUploadMbps ?? this.measuredUploadMbps,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }

  @override
  List<Object?> get props => [
        uploadKbps,
        downloadKbps,
        mode,
        overheadBytes,
        measuredDownloadMbps,
        measuredUploadMbps,
        latencyMs,
      ];
}
