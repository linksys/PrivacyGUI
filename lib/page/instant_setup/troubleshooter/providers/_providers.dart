import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/services/pnp_isp_service.dart';

export 'pnp_isp_settings_provider.dart';

final pnpIspServiceProvider = Provider<PnpIspService>((ref) {
  final routerRepository = ref.watch(routerRepositoryProvider);
  return PnpIspService(routerRepository);
});
