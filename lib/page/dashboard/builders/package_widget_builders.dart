import 'package:flutter/material.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Custom component builders for package widget templates.
///
/// Extends [UiKitCatalog.standardBuilders] with PrivacyGUI-specific
/// components that don't belong in the shared UI kit (e.g., QR code
/// requires `qr_flutter` which is only in PrivacyGUI's pubspec).
class PackageWidgetBuilders {
  static final all = <String, ComponentBuilder>{
    'AppQrCode': _buildQrCode,
  };

  static Widget _buildQrCode(
    BuildContext context,
    Map<String, dynamic> props, {
    void Function(Map<String, dynamic>)? onAction,
    List<Widget>? children,
  }) {
    final data = props['data'] as String? ?? '';
    final size = (props['size'] as num?)?.toDouble() ?? 200.0;

    if (data.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: AppText.bodySmall('No QR data')),
      );
    }

    return QrImageView(
      data: data,
      size: size,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(color: Colors.black),
      dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
    );
  }
}
