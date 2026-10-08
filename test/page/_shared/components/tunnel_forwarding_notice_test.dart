import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/tunnel_forwarding_notice.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

class _WanData extends WanDataNotifier {
  _WanData(this.kind);
  final String kind;

  @override
  Future<WanData> build() async {
    if (!BuildConfig.autoIPoEEnabled) {
      fail('disabled notice must not read WAN status');
    }
    return WanData(
        model: WanStatusUIModel(
      isUp: true,
      ipAddress: '192.0.2.1',
      subnetMask: '255.255.255.0',
      addressingType: kind,
      mtu: 1500,
    ));
  }
}

void main() {
  for (final language in ['en', 'ja', 'fr']) {
    for (final kind in ['MAP-E', 'DS-Lite', 'IPIP', 'DHCP']) {
      testWidgets('$language $kind forwarding notice follows build option',
          (tester) async {
        await tester.pumpWidget(ProviderScope(
          overrides: [wanDataProvider.overrideWith(() => _WanData(kind))],
          child: MaterialApp(
            theme: AppTheme.create(brightness: Brightness.light),
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: TunnelForwardingNotice()),
          ),
        ));
        await tester.pumpAndSettle();
        if (!BuildConfig.autoIPoEEnabled || kind == 'DHCP') {
          expect(find.byType(AppText), findsNothing);
        } else {
          final messages = language == 'ja'
              ? {
                  'MAP-E': 'MAP-Eでは、ISPから割り当てられたポートのみIPv4の着信に利用できます。',
                  'DS-Lite':
                      'DS-LiteのIPv4着信はISP側のNATに依存します。ルーターのポート設定だけでは開放できません。',
                  'IPIP': 'IPIPのIPv4着信は、ISPが提供するアドレスとサービスの条件に依存します。',
                }
              : {
                  'MAP-E':
                      'MAP-E: only ports assigned by your ISP can receive inbound IPv4 connections.',
                  'DS-Lite':
                      'DS-Lite: inbound IPv4 access is controlled by your ISP’s NAT. Local port rules alone cannot open it.',
                  'IPIP':
                      'IPIP: inbound IPv4 access depends on the address and service supplied by your ISP.',
                };
          expect(find.text(messages[kind]!), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
