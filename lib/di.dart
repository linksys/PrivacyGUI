import 'package:get_it/get_it.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';

final getIt = GetIt.instance;

void dependencySetup() {
    getIt.registerSingleton<ServiceHelper>(ServiceHelper());
}