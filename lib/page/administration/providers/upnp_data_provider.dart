import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/administration/services/usp_upnp_data_service.dart';

/// Whether UPnP is on (`Device.UPnP.Device.Enable`), for the dashboard's
/// Firewall card (#1130).
///
/// L1: not autoDispose. The router pushes nothing for this leaf, so it is read
/// again only by the dashboard's refresh and by a save on the Administration
/// page, which invalidates it.
final upnpDataProvider = FutureProvider<bool>(
  (ref) => ref.read(uspUpnpDataServiceProvider).fetchEnabled(),
);
