import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moab_poc/design/colors.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

import '../components/base_components/button/primary_button.dart';

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
        Text(
          'Push Notification:',
          style: Theme.of(context)
              .textTheme
              .headline2
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('FCM Token:'),
                    Visibility(
                      visible: _fcmToken != null,
                      child: GestureDetector(
                          onTap: _fcmToken != null
                              ? () {
                                  _copyToClipboard(_fcmToken!);
                                }
                              : null,
                          child: const Icon(Icons.paste)),
                    ),
                    Text(_fcmToken ?? 'No FCM Token'),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('APNS Token:'),
                    Text(_apnsToken ?? 'No APNS Token'),
                    Visibility(
                      visible: _apnsToken != null,
                      child: GestureDetector(
                          onTap: _apnsToken != null
                              ? () {
                                  _copyToClipboard(_apnsToken!);
                                }
                              : null,
                          child: const Icon(Icons.paste)),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                  const Text('Foreground Push Notification'),
                  Switch(value: _streamSubscription != null, onChanged: (value) {
                    _toggleForegroundNotification(value);
                  })
                ],)
              ],
            ),
          ),
        ),
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
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Throw a test exception!!')));
            throw Exception('Throw a test exception!!');
          },
        )
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
        _streamSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final title = message.notification?.title ?? '';
          final msg = message.notification?.body ?? '';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Receive notification: title: $title, body: $msg')));
        });
      } else {
        _streamSubscription?.cancel();
        _streamSubscription = null;
      }
    });
  }
}
