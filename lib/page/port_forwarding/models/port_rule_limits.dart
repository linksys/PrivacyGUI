/// The rules a forwarding or triggering rule must meet before it is saved:
/// FWDEV#204's limits and checks, as pure functions over the UI models.
///
/// Here in `models/` rather than `services/` because the dialogs and tabs use
/// them, and the Presentation layer may depend on models, not on services
/// (constitution §5.4; §5.4.4 #4 lets UI models carry validation logic).
library;

import 'dart:convert';

import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/port_overlap.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';

/// FWDEV#204's rule limits, which are JNAP 1.0's. A rule past one is
/// refused only when its own Set is checked, so the UI stops at the limit.
const kMaxSinglePortForwardingRules = 50;
const kMaxPortRangeForwardingRules = 25;
const kMaxPortTriggeringRules = 25;

/// [rules] without [editing], for the overlap checks below. By identity, not
/// `==`: two unsaved rules can be equal field for field.
List<T> othersThan<T>(List<T> rules, T? editing) => [
      for (final r in rules)
        if (!identical(r, editing)) r
    ];

/// FWDEV#204's description limit, in bytes: the FW checks `strlen`, so a CJK
/// character counts three.
const kMaxRuleDescriptionBytes = 32;

/// Whether [description] is longer than the FW stores. A longer one is not
/// refused on Add: the FW drops it and saves the rule with no description.
bool descriptionTooLong(String description) =>
    utf8.encode(description).length > kMaxRuleDescriptionBytes;

/// Whether a forwarding rule's external ports collide with any of [others].
///
/// [others] is every other forwarding rule; leave out the rule being edited.
bool forwardingOverlaps({
  required int externalPort,
  required int externalPortEndRange,
  required String protocol,
  required List<PortForwardingRuleUIModel> others,
}) {
  for (final o in others) {
    if (!protocolsShare(o.protocol, protocol)) continue;
    if (portRangesOverlap(externalPort, externalPortEndRange, o.externalPort,
        o.externalPortEndRange)) {
      return true;
    }
  }
  return false;
}

/// Whether a trigger range overlaps another triggering rule's trigger range.
/// Protocol is not compared: 1.0 stores every trigger as TCP and UDP.
///
/// [others] is every other triggering rule; leave out the rule being edited.
bool triggerRangeOverlaps({
  required int port,
  required int portEndRange,
  required List<PortTriggeringRuleUIModel> others,
}) =>
    others.any((o) => portRangesOverlap(
        port, portEndRange, o.triggerPort, o.triggerPortEndRange));

/// Whether a forwarded range overlaps another triggering rule's forwarded
/// range. Protocol is not compared, as with [triggerRangeOverlaps].
bool forwardRangeOverlaps({
  required int port,
  required int portEndRange,
  required List<PortTriggeringRuleUIModel> others,
}) =>
    others.any((o) => o.forwardRules.any((f) => portRangesOverlap(
        port, portEndRange, f.forwardPort, f.forwardPortEndRange)));
