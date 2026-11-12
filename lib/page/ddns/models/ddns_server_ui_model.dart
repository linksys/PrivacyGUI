import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';

/// A Dynamic DNS provider the router offers: one enabled
/// `Device.DynamicDNS.Server.{i}` row.
///
/// The provider dropdown lists these in instance order after "Disabled".
/// Nothing about a provider is hard-coded in the app, so a provider the
/// firmware adds as a `Server` row appears without an app release
/// (linksys/FWDEV#191, API contract item 1).
class DdnsServerUIModel extends Equatable {
  /// The row's path without its trailing dot (`Device.DynamicDNS.Server.1`).
  ///
  /// This is the form `Client.{i}.Server` reads back in, and the form the page
  /// writes, so the two compare without normalising.
  final String path;

  /// The label the router gives the provider (`DynDNS`, `No-IP` as shipped).
  final String name;

  const DdnsServerUIModel({required this.path, required this.name});

  /// The stable, data-derived key of this provider's dropdown item for E2E
  /// selectors (constitution Article XVI §16.3): a slug of [name], then the
  /// row's instance number, then `unnamed`.
  String get identifierKey => ruleIdentifierKey(name, path);

  @override
  List<Object?> get props => [path, name];
}
