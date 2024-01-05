import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ios_push_notification_plugin/ios_push_notification_plugin.dart';
import 'package:linksys_app/provider/connectivity/connectivity_provider.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/core/bluetooth/bluetooth.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/mdns/mdns_helper.dart';
import 'package:linksys_app/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/landing/view/debug_device_info_view.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/provider/smart_device_provider.dart';
import 'package:linksys_app/firebase/analytics.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/panel/general_expansion.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'export_log_base.dart'
    if (dart.library.io) 'export_log_mobile.dart'
    if (dart.library.html) 'export_log_web.dart';

class DebugToolsView extends ConsumerStatefulWidget {
  const DebugToolsView({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<DebugToolsView> createState() => _DebugToolsViewState();
}

class _DebugToolsViewState extends ConsumerState<DebugToolsView> {
  StreamSubscription? _streamSubscription;
  String? _fcmToken;
  String? _apnsToken;
  final CloudEnvironment _selectedEnv = cloudEnvTarget;

  String appInfo = '';

  @override
  void initState() {
    super.initState();
    checkTokens();
    setState(() {
      getAppInfoLogs().then((value) => appInfo = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      scrollable: true,
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: const AppText.titleLarge(
          'Debug Tools',
        ),
        content: _content(),
      ),
    );
  }

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._buildInfo(),
        const AppText.bodyLarge(
          'Log:',
        ),
        const AppGap.regular(),
        AppFilledButton(
          'Export log file',
          onTap: () async {
            exportLog(context);
          },
        ),
        const AppGap.regular(),
        ..._buildDebug(),
        const AppGap.regular(),
      ],
    );
  }

  List<Widget> _buildInfo() {
    return [
      ..._buildBasicInfo(),
      ..._buildConnectionInfo(),
      // ..._buildCloudApp(),
      ..._buildPushNotificationInfo(),
      _buildSmartDeviceTile(),
    ];
  }

  List<Widget> _buildDebug() {
    if (kReleaseMode) return [];
    return [
      // ..._buildBluetoothTestSection(),
      // ..._buildMdnsTestSection(),
      AppPanelWithSwitch(
        value: showDebugPanel,
        title: 'Enable network debug panel',
        onChangedEvent: (value) {
          setState(() {
            showDebugPanel = value;
          });
        },
      ),
      AppFilledButton(
        'Raise an Exception!',
        onTap: () async {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Throw a test exception!!')));
          // FirebaseCrashlytics.instance.crash();
          logEvent(eventName: 'testEvent');
          throw Exception('Test Exception!!!');
        },
      ),
      AppFilledButton(
        'Log a test event',
        onTap: () async {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Event logged!')));
          // FirebaseCrashlytics.instance.crash();
          logEvent(eventName: 'event_hello_world', parameters: {
            'time': DateTime.now().millisecondsSinceEpoch,
          });
        },
      ),
      const AppGap.regular(),
    ];
  }

  List<Widget> _buildBasicInfo() {
    return [
      AppExpansion(
        title: 'Basic Info',
        children: [
          AppText.bodyMedium(appInfo),
          const AppGap.regular(),
          AppFilledButton(
            'More',
            onTap: () => _goToDeviceInfoPage(context),
          ),
          const AppGap.regular(),
        ],
      ),
    ];
  }

  List<Widget> _buildConnectionInfo() {
    final connectivityState = ref.watch(connectivityProvider);
    return [
      AppExpansion(
        initiallyExpanded: true,
        title: 'Connection Info',
        children: [
          AppText.bodyMedium(
              'Router: ${connectivityState.connectivityInfo.routerType.name}'),
          AppText.bodyMedium(
              'Connectivity: ${connectivityState.connectivityInfo.type.name}'),
          AppText.bodyMedium(
              'Gateway Ip: ${connectivityState.connectivityInfo.gatewayIp}'),
          AppText.bodyMedium(
              'SSID: ${connectivityState.connectivityInfo.ssid}'),
          const AppGap.regular(),
        ],
      ),
    ];
  }

  Widget _buildSmartDeviceTile() {
    final smartDevice = ref.watch(smartDeviceProvider);
    return AppExpansion(
      title: 'Linksys Smart Devices',
      children: [
        AppText.labelLarge('SmartDeviceId: ${smartDevice.id}'),
        AppText.labelLarge('SmartDevice Verified: ${smartDevice.isVerified}'),
        AppFilledButton(
          'Register Smartdevice',
          onTap: () {
            SharedPreferences.getInstance().then((prefs) {
              final deviceToken = prefs.getString(pDeviceToken);
              if (deviceToken != null) {
                ref
                    .read(smartDeviceProvider.notifier)
                    .registerSmartDevice(deviceToken);
              } else {}
            });
          },
        ),
        AppFilledButton(
          'Test',
          onTap: () async {
            // ref.read(smartDeviceProvider.notifier).fetchEventSubscriptions();
            showFailedSnackBar(context, '123');
          },
        ),
      ],
    );
  }

  List<Widget> _buildPushNotificationInfo() {
    if (kIsWeb) return [];
    return [
      AppExpansion(
        title: 'PushNotification Info',
        children: [
          Offstage(
            offstage: Platform.isIOS,
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: AppText.bodyMedium('FCM Token:'),
                ),
                IconButton(
                    onPressed: _fcmToken != null
                        ? () {
                            _shareToken(_fcmToken!);
                          }
                        : null,
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                    )),
                AppText.bodyMedium(_fcmToken ?? 'No FCM Token'),
              ],
            ),
          ),
          const AppGap.small(),
          Offstage(
            offstage: Platform.isAndroid,
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const AppText.bodyMedium('APNS Token:'),
                IconButton(
                    onPressed: _apnsToken != null
                        ? () {
                            _shareToken(_apnsToken!);
                          }
                        : null,
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                    )),
                AppText.bodyMedium(_apnsToken ?? 'No APNS Token'),
              ],
            ),
          ),
          const AppGap.regular(),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Foreground Push Notification'),
              Switch(
                  value: _streamSubscription != null,
                  onChanged: (value) {
                    _toggleForegroundNotification(value);
                  })
            ],
          ),
          const AppGap.regular(),
        ],
      ),
    ];
  }

  List<Widget> _buildBiometricsInfo() {
    return [
      ExpansionTile(
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        initiallyExpanded: true,
        title: const AppText.labelLarge('Biometrics'),
        children: [
          AppFilledButton(
            'Test Biometrics',
            onTap: () async {},
          )
        ],
      ),
    ];
  }

  List<Widget> _buildBluetoothTestSection() {
    return [
      AppExpansion(
        title: 'Bluetooth testing',
        children: [
          AppFilledButton(
            'Scan & connect',
            onTap: () async {
              await BluetoothManager().scan();
              final results = BluetoothManager().results;
              if (results.isNotEmpty) {
                logger.d('BT Scan result: ${results.length}');
                BluetoothManager().connect(results[0].device);
              } else {
                logger.d('BT No scan result');
              }
            },
          ),
          AppFilledButton(
            'Test get Mac address',
            onTap: () async {
              final repository = ref.read(routerRepositoryProvider)
                ..enableBTSetup = true;
              final result1 = await repository
                  .send(
                    JNAPAction.getMACAddress,
                    auth: true,
                  )
                  .then<JNAPSuccess?>((value) => value)
                  .onError((error, stackTrace) {
                logger.e('Error', error: error, stackTrace: stackTrace);
                return null;
              });
              logger.d('result1: $result1}');
              final result2 = await repository.send(JNAPAction.getVersionInfo);
              logger.d('result2: $result2}');
              // repository.setDeviceMode('Master');
              repository.enableBTSetup = false;
            },
          ),
          AppFilledButton(
            'Disconnect',
            onTap: () {
              BluetoothManager().disconnect();
            },
          ),
          const AppGap.regular(),
        ],
      ),
    ];
  }

  List<Widget> _buildMdnsTestSection() {
    return [
      ExpansionTile(
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        initiallyExpanded: true,
        title: const AppText.bodyLarge('MDNS testing'),
        children: [
          AppFilledButton(
            'discover',
            onTap: () async {
              const String name = '_dartobservatory._tcp.local';
              String httpType = "_http._tcp";
              String omsgType = "_omsg._tcp";

              final result = await Future.wait([
                MDnsHelper.discover(httpType),
                MDnsHelper.discover(omsgType)
              ]);
              logger.d('Result: $result');
            },
          ),
          const AppGap.regular(),
        ],
      ),
    ];
  }

  _shareToken(String token) async {
    Size size = MediaQuery.of(context).size;
    final result = await Share.shareWithResult(
      token,
      subject: 'Token',
      sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height / 2),
    );
    print('Share result: $result');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Share result: ${result.status}"),
    ));
  }

  Future<void> checkTokens() async {
    final instance = FirebaseMessaging.instance;
    final fcmToken = await instance.getToken();
    final apnsToken = await instance.getAPNSToken();
    setState(() {
      _fcmToken = fcmToken;
      _apnsToken = apnsToken;
    });
  }

  // This function is triggered when the copy icon is pressed
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Copied to clipboard'),
    ));
  }

  _toggleForegroundNotification(bool value) {
    setState(() {
      if (value) {
        if (Platform.isAndroid) {
          _streamSubscription =
              FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            final title = message.notification?.title ?? '';
            final msg = message.notification?.body ?? '';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text('Receive notification: title: $title, body: $msg')));
          });
        } else if (Platform.isIOS) {
          IosPushNotificationPlugin().requestAuthorization().then((value) {
            if (value) {
              _streamSubscription = IosPushNotificationPlugin()
                  .pushNotificationStream
                  .listen((event) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Receive notification: event: $event')));
              });
            }
          });
        }
      } else {
        _streamSubscription?.cancel();
        _streamSubscription = null;
      }
    });
  }

  void _goToDeviceInfoPage(BuildContext context) {
    showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return const DebugDeviceInfoView();
        });
  }
}

Future<SecurityContext> loader(BuildContext context) async {
  return SecurityContext();
}
