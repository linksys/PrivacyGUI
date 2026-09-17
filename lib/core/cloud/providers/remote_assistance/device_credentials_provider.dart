import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';

/// Provides [DeviceCredentials] for Remote Assistance API calls.
///
/// All three values come from the session's device info, which is where the login
/// already puts them. Returns null when the router cannot supply a complete,
/// well-formed set — the support page's entry point reads that as "not available"
/// and says so.
///
/// **Why not from the devices table (PrivacyGUI#1582).** The MAC and the UUID used
/// to come from the master node, i.e. from `Device.Hosts.Host.{i}` — the UUID from
/// `DeviceID`, and the node itself found via `DeviceRole`. FL-WRT 2.0 deleted both
/// leaves, so on that firmware the master could not be identified at all,
/// credentials were always null, and Remote Assistance was permanently
/// un-startable with nothing on screen to say why. Reading the session instead is
/// not a workaround for that: it removes the dependency, and with it the
/// `'GATEWAY'` string that `MasterNode.deviceId` falls back to when no node
/// answers. Guardian answers `403` to a wrong MAC, so that fallback would have
/// become a live failure the moment the UUID was fixed.
///
/// **The shape checks are the caller's protection, not validation theatre.**
/// Measured against Guardian on 2026-09-17: a wrong MAC and a wrong UUID both
/// answer `403`, and so does the *correct* UUID in lower case. Every one of those
/// surfaces to a person as "Remote Assistance does nothing", which is the symptom
/// this ticket removes — so a malformed value is refused here, where it can be
/// reported, rather than sent to be rejected.
final deviceCredentialsProvider = Provider<DeviceCredentials?>((ref) {
  final deviceInfo = ref.watch(sessionProvider).deviceInfo;
  if (deviceInfo == null) return null;

  final serialNumber = deviceInfo.serialNumber;
  final macAddress = deviceInfo.baseMacAddress;
  final deviceUuid = deviceInfo.deviceUuid;

  if (serialNumber.isEmpty) return null;
  if (macAddress == null || !_macPattern.hasMatch(macAddress)) return null;
  if (deviceUuid == null || !_uuidPattern.hasMatch(deviceUuid)) return null;

  return DeviceCredentials(
    serialNumber: serialNumber,
    macAddress: macAddress,
    deviceUUID: deviceUuid,
  );
});

/// Colon-separated hex, the form Guardian's device APIs specify.
final _macPattern = RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$');

/// Bare 8-4-4-4-12. Deliberately rejects a value that still carries the
/// `uuid::` prefix `Device.LocalAgent.EndpointID` serves it with.
final _uuidPattern = RegExp(
    r'^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$');
