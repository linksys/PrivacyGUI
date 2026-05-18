import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_notifier.dart';

final pnpProvider = NotifierProvider<PnpNotifier, PnpState>(
  PnpNotifier.new,
);
