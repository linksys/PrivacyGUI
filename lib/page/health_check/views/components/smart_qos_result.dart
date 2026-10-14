import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/health_check/models/smart_qos_recommendation.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/expansion_card.dart';
import 'package:privacygui_widgets/widgets/label/status_label.dart';

/// Smart QoS result cards, shown on the completed speed-test page.
///
/// The design (Figma `Web-Light: Speed Test` → `Smart QoS`, node 21498:262334)
/// resolves the speed-test result into a feature-configuration surface: a
/// Status card with an enable toggle, a Protection Details card describing the
/// shaping the router would apply, and an Advanced disclosure exposing the raw
/// values.
///
/// ⚠️ DISPLAY ONLY ON THIS FIRMWARE. There is no QoS/shaping write path
/// (confirmed: no CAKE/shaping JNAP action on this build) and no durable store
/// for the user's intent, so hosts render this with [readOnly] true: the toggle
/// is disabled and the card says so ([loc.smartQosPendingBackendNote]). The
/// values come from [SmartQosRecommendation.fromResult], a client-side mirror of
/// the router's arithmetic, and every derived value is labelled as an estimate
/// ([loc.smartQosEstimateNote]) because the mirror is unvalidated against the
/// firmware. When a transport lands: persist intent through [onEnabledChanged],
/// pass [readOnly] false, read values from the router, delete the mirror.
class SmartQosResult extends StatefulWidget {
  const SmartQosResult({
    super.key,
    required this.recommendation,
    this.initiallyEnabled = false,
    this.onEnabledChanged,
    this.readOnly = false,
  });

  final SmartQosRecommendation recommendation;

  /// Whether the enable toggle starts on. Defaults to off since there is no
  /// backend state to reflect.
  final bool initiallyEnabled;

  /// Invoked when the user flips the enable toggle. Records intent only — see
  /// the class doc: there is no shaping write path on this firmware.
  final ValueChanged<bool>? onEnabledChanged;

  /// When true the enable control is shown disabled and the card reads as a
  /// preview: nothing is recorded. Hosts pass this until they can persist the
  /// user's choice and read it back (there is no shaping backend on this
  /// firmware and no durable intent store yet), so the toggle never promises an
  /// effect it cannot deliver.
  final bool readOnly;

  @override
  State<SmartQosResult> createState() => _SmartQosResultState();
}

class _SmartQosResultState extends State<SmartQosResult> {
  late bool _enabled = widget.initiallyEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _statusCard(context),
        const AppGap.small3(),
        _protectionDetailsCard(context),
        const AppGap.small3(),
        _explainerCard(context),
      ],
    );
  }

  // ── Status ──────────────────────────────────────────────────

  Widget _statusCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleSmall(loc(context).smartQosStatus),
              AppStatusLabel(
                isOff: !_enabled,
                label: loc(context).smartQosActive,
                offLabel: loc(context).smartQosInactive,
              ),
            ],
          ),
          const AppGap.medium(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyLarge(loc(context).smartQosEnable),
                    const AppGap.small2(),
                    AppText.bodySmall(
                      loc(context).smartQosEnableDescription,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
              const AppGap.medium(),
              AppSwitch(
                semanticLabel: loc(context).smartQosEnable,
                value: _enabled,
                onChanged: widget.readOnly
                    ? null
                    : (value) {
                        setState(() => _enabled = value);
                        widget.onEnabledChanged?.call(value);
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Protection Details ──────────────────────────────────────

  Widget _protectionDetailsCard(BuildContext context) {
    final rec = widget.recommendation;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.titleSmall(loc(context).smartQosProtectionDetails),
          const AppGap.small2(),
          AppText.bodySmall(
            loc(context).smartQosEstimateNote,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const AppGap.medium(),
          _detailRow(
            context,
            loc(context).smartQosUploadManagedAt,
            '${rec.uploadMbps.toStringAsFixed(1)} ${loc(context).mbps}',
          ),
          const AppGap.small2(),
          _detailRow(
            context,
            loc(context).download,
            rec.isDownloadUnlimited
                ? loc(context).smartQosNoLimitNeeded
                : '${rec.downloadMbps.toStringAsFixed(1)} ${loc(context).mbps}',
          ),
          const AppGap.medium(),
          _advancedDisclosure(context, rec),
          const AppGap.small2(),
          AppText.bodySmall(
            loc(context).smartQosPendingBackendNote,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: AppText.bodyMedium(
            label,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const AppGap.medium(),
        AppText.labelLarge(value),
      ],
    );
  }

  // ── Advanced disclosure ─────────────────────────────────────

  Widget _advancedDisclosure(
      BuildContext context, SmartQosRecommendation rec) {
    return AppExpansionCard(
      identifier: 'smart-qos-advanced',
      title: loc(context).smartQosAdvanced,
      expandedIcon: LinksysIcons.remove,
      collapsedIcon: LinksysIcons.add,
      children: [
        _readonlyField(
          context,
          loc(context).smartQosUploadKbps,
          '${rec.uploadKbps}',
        ),
        const AppGap.small2(),
        _readonlyField(
          context,
          loc(context).smartQosDownloadKbps,
          '${rec.downloadKbps}',
        ),
        const AppGap.small2(),
        _readonlyField(
          context,
          loc(context).smartQosMode,
          rec.mode == SmartQosMode.uploadOnly
              ? loc(context).smartQosModeUploadOnly
              : loc(context).smartQosModeBoth,
        ),
        const AppGap.small2(),
        _readonlyField(
          context,
          loc(context).smartQosOverheadBytes,
          '${rec.overheadBytes}',
        ),
      ],
    );
  }

  /// Advanced values are read-only on this firmware: with no write path there is
  /// nothing to submit, so editing them would be a false affordance. Rendered as
  /// a labelled value rather than an editable [AppTextField].
  Widget _readonlyField(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: AppText.bodySmall(
            label,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const AppGap.medium(),
        AppText.bodyMedium(value),
      ],
    );
  }

  // ── Explainer ───────────────────────────────────────────────

  Widget _explainerCard(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LinksysIcons.bolt),
          const AppGap.medium(),
          Expanded(
            child: AppText.bodyMedium(loc(context).smartQosExplainer),
          ),
        ],
      ),
    );
  }
}
