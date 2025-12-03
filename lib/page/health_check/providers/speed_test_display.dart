import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/utils/nodes.dart';

bool isDisplaySpeedTest(WidgetRef ref) {
  final modelNumber =
      ref.watch(dashboardManagerProvider).deviceInfo?.modelNumber ?? '';
  final hardwareVersion =
      ref.watch(dashboardManagerProvider).deviceInfo?.hardwareVersion ?? '1';
  return isShowSpeedTest(
      modelNumber: modelNumber, hardwareVersion: hardwareVersion);
}
