import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moab_poc/config/cloud_environment_manager.dart';
import 'package:moab_poc/network/http/extension_requests/accounts_requests.dart';
import 'package:moab_poc/network/http/http_client.dart';
import 'package:moab_poc/network/http/model/cloud_config.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/landing/view/debug_device_info_view.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:moab_poc/util/storage.dart';
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

  @override
  void initState() {
    super.initState();
    checkTokens();
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
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
        // Text(
        //   'Push Notification:',
        //   style: Theme.of(context)
        //       .textTheme
        //       .headline2
        //       ?.copyWith(color: Theme.of(context).colorScheme.primary),
        // ),
        // Card(
        //   child: Padding(
        //     padding: const EdgeInsets.all(8.0),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Wrap(
        //           alignment: WrapAlignment.start,
        //           crossAxisAlignment: WrapCrossAlignment.center,
        //           children: [
        //             const Text('FCM Token:'),
        //             Visibility(
        //               visible: _fcmToken != null,
        //               child: GestureDetector(
        //                   onTap: _fcmToken != null
        //                       ? () {
        //                           _copyToClipboard(_fcmToken!);
        //                         }
        //                       : null,
        //                   child: const Icon(Icons.paste)),
        //             ),
        //             Text(_fcmToken ?? 'No FCM Token'),
        //           ],
        //         ),
        //         const SizedBox(
        //           height: 8,
        //         ),
        //         Wrap(
        //           alignment: WrapAlignment.start,
        //           crossAxisAlignment: WrapCrossAlignment.center,
        //           children: [
        //             const Text('APNS Token:'),
        //             Text(_apnsToken ?? 'No APNS Token'),
        //             Visibility(
        //               visible: _apnsToken != null,
        //               child: GestureDetector(
        //                   onTap: _apnsToken != null
        //                       ? () {
        //                           _copyToClipboard(_apnsToken!);
        //                         }
        //                       : null,
        //                   child: const Icon(Icons.paste)),
        //             ),
        //           ],
        //         ),
        //         const SizedBox(
        //           height: 16,
        //         ),
        //         Wrap(
        //           crossAxisAlignment: WrapCrossAlignment.center,
        //           children: [
        //             const Text('Foreground Push Notification'),
        //             Switch(
        //                 value: _streamSubscription != null,
        //                 onChanged: (value) {
        //                   _toggleForegroundNotification(value);
        //                 })
        //           ],
        //         )
        //       ],
        //     ),
        //   ),
        // ),
        const SizedBox(
          height: 16,
        ),
        Text(
          'Crashlytics:',
          style: Theme.of(context)
              .textTheme
              .headline2
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
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
            // Share.shareFiles(['${Storage.logFileUri.path}'], text: 'Log file');
            final box = context.findRenderObject() as RenderBox?;
            final result = await Share.shareFilesWithResult(
                [Storage.logFileUri.path],
                text: 'Log',
                subject: 'Log file',
                sharePositionOrigin:
                    box!.localToGlobal(Offset.zero) & box.size);
            print('Share result: $result');
            if (result.status == ShareResultStatus.success) {
              Storage.deleteFile(Storage.logFileUri);
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Share result: ${result.status}"),
            ));
          },
        ),
        const SizedBox(
          height: 16,
        ),
        Text(
          'Information:',
          style: Theme.of(context)
              .textTheme
              .headline2
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        SecondaryButton(
          text: 'Read device information',
          onPress: () => _goToDeviceInfoPage(context),
        ),
        const SizedBox(
          height: 16,
        ),
        _buildEnvPickerTile(),
        const SizedBox(
          height: 16,
        ),
        Text(
          'Test API:',
          style: Theme.of(context)
              .textTheme
              .headline2
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        SecondaryButton(
          text: 'Test Get Profile',
          onPress: () async {
            SecurityContext securityContext = SecurityContext(withTrustedRoots: true);
            final publicKey = (await rootBundle.load('assets/keys/testCert.pem'))
                .buffer
                .asInt8List();
            final privateKey = (await rootBundle.load('assets/keys/testKey.key'))
                .buffer
                .asInt8List();
            securityContext.useCertificateChainBytes(publicKey);
            securityContext.usePrivateKeyBytes(privateKey);
            final client = MoabHttpClient.withCert(securityContext);
            await client.getAccountSelf();
          },
        ),
      ],
    );
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
        _streamSubscription =
            FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final title = message.notification?.title ?? '';
          final msg = message.notification?.body ?? '';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Receive notification: title: $title, body: $msg')));
        });
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
      }
    );
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
                    });
                  },
                ),
                const SizedBox(height: 24,)
              ],
            );
    });
  }
}
