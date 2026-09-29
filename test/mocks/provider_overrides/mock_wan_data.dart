import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';

/// `wanDataProvider` fakes for the three states its consumers must tell apart.
///
/// WHY ALL THREE LIVE TOGETHER. `mock_dashboard_cards.dart` already has a
/// `FixedWanDataNotifier`, but only the settled-with-data case — which is the only one a
/// dashboard card needs. The Internet Settings page needs the other two as well, because
/// #1613 was a defect in exactly the states that file cannot express: an `AsyncError`
/// rendered as a confident "offline", indistinguishable from a device that genuinely
/// reported no address.
///
/// Three test files were each declaring their own private copies of these. Collected here
/// so a new test does not have to rediscover which states exist, and so "what does an
/// unreadable WAN look like" has one answer in this repo.
///
/// The override helpers below are the intended entry point; the classes are public only
/// because a test occasionally needs to subclass one.

/// A WAN that settles with [model].
class FixedWan extends WanDataNotifier {
  FixedWan(this.model);
  final WanStatusUIModel model;
  @override
  Future<WanData> build() async => WanData(model: model);
}

/// A WAN whose fetch throws, reproducing the ordinary production path where
/// `uspWanDataServiceProvider` throws because `uspClientProvider` is null — session not
/// yet established, re-auth, dropped socket.
///
/// This provider is not autoDispose and has no retry, so in production this state persists
/// until something else invalidates it. That stickiness is what made #1613 a real defect
/// rather than a momentary flicker.
class ErrorWan extends WanDataNotifier {
  ErrorWan(
      [this.error = const ServiceNotInitializedError(
          detail: 'USP service not available')]);
  final Object error;
  @override
  Future<WanData> build() async => throw error;
}

/// A WAN whose first load never completes — the state before anything has been read.
class LoadingWan extends WanDataNotifier {
  @override
  Future<WanData> build() => Completer<WanData>().future;
}

/// A WAN up with an address. The default for "nothing interesting about the WAN here".
const wanUpModel = WanStatusUIModel(
  isUp: true,
  ipAddress: '100.64.0.10',
  subnetMask: '255.255.255.0',
  addressingType: 'DHCP',
  mtu: 1500,
);

/// A WAN the device reports as having NO address — link down, or up without a lease yet.
///
/// Distinct from [ErrorWan] on purpose: here the device answered, so "offline" is a true
/// reading. Conflating the two is the defect these fakes exist to keep testable.
const wanNoAddressModel = WanStatusUIModel(
  isUp: false,
  ipAddress: '',
  subnetMask: '',
  addressingType: '',
  mtu: 1500,
);

/// Override `wanDataProvider` with a settled value (defaults to [wanUpModel]).
Override wanDataOverride([WanStatusUIModel? model]) =>
    wanDataProvider.overrideWith(() => FixedWan(model ?? wanUpModel));

/// Override `wanDataProvider` with a fetch that throws.
Override wanDataErrorOverride([Object? error]) => wanDataProvider
    .overrideWith(() => error == null ? ErrorWan() : ErrorWan(error));

/// Override `wanDataProvider` with a first load that never completes.
Override wanDataLoadingOverride() =>
    wanDataProvider.overrideWith(() => LoadingWan());
