import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ios_push_notification_plugin/ios_push_notification_plugin.dart';
import 'package:linksys_moab/bloc/connectivity/connectivity_provider.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/constants/build_config.dart';
import 'package:linksys_moab/network/bluetooth/bluetooth.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/jnap_transaction.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/network/mdns/mdns_helper.dart';
import 'package:linksys_moab/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/landing/view/debug_device_info_view.dart';
import 'package:linksys_moab/repository/router/commands/_commands.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/util/storage.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:share_plus/share_plus.dart';

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

  late final RouterRepository _routerRepository;
  late final NetworkCubit _networkCubit;

  String appInfo = '';

  @override
  void initState() {
    _networkCubit = context.read<NetworkCubit>();
    _routerRepository = context.read<RouterRepository>();
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
        header: const AppText.screenName(
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
        const AppText.descriptionMain(
          'Log:',
        ),
        const AppGap.regular(),
        AppPrimaryButton(
          'Export log file',
          onTap: () async {
            final file = File.fromUri(Storage.logFileUri);
            final appInfo = await getAppInfoLogs();
            final screenInfo = getScreenInfo(context);
            final String shareLogFilename =
                'moab-log-${DateFormat("yyyy-MM-dd_HH_mm_ss").format(DateTime.now())}.txt';
            final String shareLogPath =
                '${Storage.tempDirectory?.path}/$shareLogFilename';
            final value = await file.readAsBytes();

            String content =
                '$appInfo\n$screenInfo\n${String.fromCharCodes(value)}';
            await Storage.saveFile(Uri.parse(shareLogPath), content);

            Size size = MediaQuery.of(context).size;
            final result = await Share.shareFilesWithResult(
              [shareLogPath],
              text: 'Moab Log',
              subject: 'Log file',
              sharePositionOrigin:
                  Rect.fromLTWH(0, 0, size.width, size.height / 2),
            );
            if (result.status == ShareResultStatus.success) {
              Storage.deleteFile(Storage.logFileUri);
              Storage.deleteFile(Uri.parse(shareLogPath));
              Storage.createLoggerFile();
            }
            showSnackBar(context, Text("Share result: ${result.status}"));
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
      AppPrimaryButton(
        'Raise an Exception!',
        onTap: () async {
          // ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(content: Text('Throw a test exception!!')));
          // throw Exception('Throw a test exception!!');
          final repo = context.read<RouterRepository>();
          // final result = await repo.isAdminPasswordDefault();
          // logger.d('Result: $result');
          // final result1 = await repo.getMACAddress();
          // logger.d('Result1: $result1');

          final builder = JNAPTransactionBuilder()
              .add(JNAPAction.isAdminPasswordDefault)
              .add(JNAPAction.isAdminPasswordSetByUser);
          final result = await repo.transaction(builder);
          logger.d('Result: $result');
        },
      ),
      const AppGap.regular(),
    ];
  }

  List<Widget> _buildBasicInfo() {
    return [
      ExpansionTile(
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        initiallyExpanded: true,
        title: const AppText.descriptionMain('Basic Info'),
        children: [
          AppText.descriptionSub(appInfo),
          const AppGap.regular(),
          AppPrimaryButton(
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
      ExpansionTile(
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        initiallyExpanded: true,
        title: const AppText.descriptionMain('Connection Info'),
        children: [
          AppText.descriptionSub(
              'Router: ${connectivityState.connectivityInfo.routerType.name}'),
          AppText.descriptionSub(
              'Connectivity: ${connectivityState.connectivityInfo.type.name}'),
          AppText.descriptionSub(
              'Gateway Ip: ${connectivityState.connectivityInfo.gatewayIp}'),
          AppText.descriptionSub(
              'SSID: ${connectivityState.connectivityInfo.ssid}'),
          const AppGap.regular(),
        ],
      ),
    ];
  }

  List<Widget> _buildPushNotificationInfo() {
    return [
      ExpansionTile(
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        initiallyExpanded: true,
        title: const AppText.descriptionMain('PushNotification Info'),
        children: [
          Offstage(
            offstage: Platform.isIOS,
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: AppText.descriptionSub('FCM Token:'),
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
                AppText.descriptionSub(_fcmToken ?? 'No FCM Token'),
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
                const AppText.descriptionSub('APNS Token:'),
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
                AppText.descriptionSub(_apnsToken ?? 'No APNS Token'),
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

  List<Widget> _buildBluetoothTestSection() {
    return [
      ExpansionTile(
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        initiallyExpanded: true,
        title: const AppText.descriptionMain('Bluetooth testing'),
        children: [
          AppPrimaryButton(
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
          AppPrimaryButton(
            'Test get Mac address',
            onTap: () async {
              final repository = context.read<RouterRepository>()
                ..enableBTSetup = true;
              final result1 = await repository
                  .getMACAddress()
                  .then<JNAPSuccess?>((value) => value)
                  .onError((error, stackTrace) {
                logger.e('Error', error, stackTrace);
                return null;
              });
              logger.d('result1: $result1}');
              final result2 = await repository.getVersionInfo();
              logger.d('result2: $result2}');
              // repository.setDeviceMode('Master');
              repository.enableBTSetup = false;
            },
          ),
          AppPrimaryButton(
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
        title: const AppText.descriptionMain('MDNS testing'),
        children: [
          AppPrimaryButton(
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
