import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
import 'package:ios_push_notification_plugin/ios_push_notification_plugin.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/security/bloc.dart';
import 'package:linksys_moab/bloc/security/event.dart';
import 'package:linksys_moab/bloc/security/state.dart';
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/constants/build_config.dart';
import 'package:linksys_moab/network/http/model/cloud_app.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_moab/page/landing/view/debug_device_info_view.dart';
import 'package:linksys_moab/repository/router/commands/core_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/util/storage.dart';
import 'package:share_plus/share_plus.dart';

class DebugToolsView extends StatefulWidget {
  const DebugToolsView({
    Key? key,
  }) : super(key: key);

  @override
  State<DebugToolsView> createState() => _DebugToolsViewState();
}

class _DebugToolsViewState extends State<DebugToolsView> {
  StreamSubscription? _streamSubscription;
  String? _fcmToken;
  String? _apnsToken;
  CloudEnvironment _selectedEnv = cloudEnvTarget;

  late final ConnectivityCubit _connectivityCubit;
  late final RouterRepository _routerRepository;
  late final AuthBloc _authBloc;
  late final NetworkCubit _networkCubit;

  String appInfo = '';

  @override
  void initState() {
    _connectivityCubit = context.read<ConnectivityCubit>();
    _authBloc = context.read<AuthBloc>();
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
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Debug Tools',
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
        Text(
          'Log:',
          style: Theme.of(context)
              .textTheme
              .headline2
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        SecondaryButton(
          text: 'Export log file',
          onPress: () async {
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
        box16(),
        _buildEnvPickerTile(),
        ..._buildDebug(),
        box16(),
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
      ..._buildSubscriptionTesting(),
      SecondaryButton(
        text: 'Raise an Exception!',
        onPress: () {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Throw a test exception!!')));
          throw Exception('Throw a test exception!!');
        },
      ),
      const SizedBox(
        height: 16,
      ),
    ];
  }

  List<Widget> _buildBasicInfo() {
    return [
      ExpansionTile(
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        initiallyExpanded: true,
        title: Text('Basic Info'),
        children: [
          Text(appInfo),
          box16(),
          SecondaryButton(
            text: 'More',
            onPress: () => _goToDeviceInfoPage(context),
          ),
          box16(),
        ],
      ),
    ];
  }

  List<Widget> _buildConnectionInfo() {
    return [
      ExpansionTile(
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        initiallyExpanded: true,
        title: Text('Connection Info'),
        children: [
          Text(
              'Router: ${_connectivityCubit.state.connectivityInfo.routerType.name}'),
          Text(
              'Connectivity: ${_connectivityCubit.state.connectivityInfo.type.name}'),
          Text(
              'Gateway Ip: ${_connectivityCubit.state.connectivityInfo.gatewayIp}'),
          Text('SSID: ${_connectivityCubit.state.connectivityInfo.ssid}'),
          box16(),
        ],
      ),
    ];
  }

  List<Widget> _buildCloudApp() {
    return [
      ExpansionTile(
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text('Cloud App Info'),
        onExpansionChanged: (expand) {
          if (expand) {
            setState(() {});
          }
        },
        children: [
          FutureBuilder<CloudApp>(
              future: CloudEnvironmentManager()
                  .fetchCloudApp()
                  .then((value) => CloudEnvironmentManager().loadCloudApp()),
              initialData: null,
              builder: (context, snapshot) {
                return snapshot.data == null
                    ? Text('No Data')
                    : Column(
                        children: [
                          Table(
                            border: TableBorder.all(color: Colors.white60),
                            children: [
                              ...CloudEnvironmentManager()
                                  .getCloudApp()
                                  .toJson()
                                  .entries
                                  .map((e) => TableRow(children: [
                                        Text(e.key),
                                        Text(e.value ?? '')
                                      ]))
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: PrimaryButton(
                              text: 'Register smart device',
                              onPress: snapshot.data is CloudSmartDeviceApp
                                  ? (snapshot.data as CloudSmartDeviceApp)
                                              .smartDevice
                                              .smartDeviceStatus ==
                                          'ACTIVE'
                                      ? null
                                      : _registerSmartDevice
                                  : _registerSmartDevice,
                            ),
                          ),
                        ],
                      );
              }),
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
        title: Text('PushNotification Info'),
        children: [
          Offstage(
            offstage: Platform.isIOS,
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('FCM Token:'),
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
                Text(_fcmToken ?? 'No FCM Token'),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Offstage(
            offstage: Platform.isAndroid,
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('APNS Token:'),
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
                Text(_apnsToken ?? 'No APNS Token'),
              ],
            ),
          ),
          const SizedBox(
            height: 16,
          ),
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
          box16(),
        ],
      ),
    ];
  }

  List<Widget> _buildSubscriptionTesting() {
    return [
      box16(),
      Text(
        'Default Preset:',
        style: Theme.of(context)
            .textTheme
            .headline2
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
      PrimaryButton(
        text: 'Load Security Preset',
        onPress: () {
          final repo = context.read<RouterRepository>();
          repo.isAdminPasswordDefault();

        },
      ),
      Text(
        'Subscription:',
        style: Theme.of(context)
            .textTheme
            .headline2
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
      SecondaryButton(
        text: 'Activate Trial Subscription',
        onPress: () {
          // context.read<SecurityBloc>().add(SetTrialActiveEvent());
          final repo = context.read<RouterRepository>();
          repo.getDeviceInfo();
        },
      ),
      box8(),
      SecondaryButton(
        text: 'Activate Formal Subscription',
        onPress: () {
          context.read<SecurityBloc>().add(SetFormalActiveEvent());
        },
      ),
      box8(),
      SecondaryButton(
        text: 'Turn Off Security',
        onPress: () {
          context.read<SecurityBloc>().add(TurnOffSecurityEvent());
        },
      ),
      box8(),
      SecondaryButton(
        text: 'Unsubscribe',
        onPress: () {
          context.read<SecurityBloc>().add(SetUnsubscribedEvent());
        },
      ),
      box8(),
      Row(
        children: [
          Expanded(
            child: SecondaryButton(
              text: 'Virus+1',
              onPress: () {
                context.read<SecurityBloc>().add(CyberthreatDetectedEvent(
                      type: CyberthreatType.virus,
                      number: 1,
                    ));
              },
            ),
          ),
          box8(),
          Expanded(
            child: SecondaryButton(
              text: 'Botnet+1',
              onPress: () {
                context.read<SecurityBloc>().add(CyberthreatDetectedEvent(
                      type: CyberthreatType.botnet,
                      number: 1,
                    ));
              },
            ),
          ),
        ],
      ),
      box8(),
      SecondaryButton(
        text: 'Website+1',
        onPress: () {
          context.read<SecurityBloc>().add(CyberthreatDetectedEvent(
                type: CyberthreatType.website,
                number: 1,
              ));
        },
      ),
      box16(),
    ];
  }

  _registerSmartDevice() {
    CloudEnvironmentManager().registerSmartDevice();
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

  Widget _buildEnvPickerTile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Env picker: ${_selectedEnv.name}',
          style: Theme.of(context)
              .textTheme
              .headline2
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        Text(
          'Will logout after change environment!',
          style: Theme.of(context)
              .textTheme
              .headline2
              ?.copyWith(color: Colors.red),
        ),
        SecondaryButton(
          text: 'Select environment',
          onPress: () async {
            final result = await showModalBottomSheet(
                enableDrag: false,
                context: context,
                builder: (context) => _createEnvPicker());
            setState(() {
              _selectedEnv = result;
            });
          },
        )
      ],
    );
  }

  Widget _createEnvPicker() {
    bool _isLoading = false;
    return StatefulBuilder(builder: (context, setState) {
      return _isLoading
          ? FullScreenSpinner(text: getAppLocalizations(context).processing)
          : Column(
              children: [
                ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: CloudEnvironment.values.length,
                    itemBuilder: (context, index) => GestureDetector(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: SelectableItem(
                              text: CloudEnvironment.values[index].name,
                              isSelected: _selectedEnv ==
                                  CloudEnvironment.values[index],
                              height: 66,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedEnv = CloudEnvironment.values[index];
                            });
                          },
                        )),
                const Spacer(),
                PrimaryButton(
                  text: 'Save',
                  onPress: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    final temp = cloudEnvTarget;
                    cloudEnvTarget = _selectedEnv;
                    await CloudEnvironmentManager()
                        .fetchCloudConfig()
                        .then((value) =>
                            CloudEnvironmentManager().createCloudApp())
                        .then(
                            (value) => Navigator.of(context).pop(_selectedEnv))
                        .onError((error, stackTrace) {
                      logger.e(
                          'fetch cloud config error! $cloudEnvTarget}', error);
                      setState(() {
                        _selectedEnv = temp;
                      });
                      cloudEnvTarget = temp;
                    }).whenComplete(() {
                      setState(() {
                        _isLoading = false;
                      });
                      context.read<AuthBloc>().add(Logout());
                    });
                  },
                ),
                const SizedBox(
                  height: 24,
                )
              ],
            );
    });
  }
}

Future<SecurityContext> loader(BuildContext context) async {
  return SecurityContext();
}
