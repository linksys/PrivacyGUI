import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moab_poc/network/model/command/mqtt_base_command.dart';
import 'package:moab_poc/network/mqtt_client_wrap.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

import '../../design/themes.dart';
import '../../network/model/command/impl/counter_command.dart';
import '../../util/logger.dart';

void main() {
  runApp(const MoabApp());
}

class MoabApp extends StatelessWidget {
  const MoabApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: MoabTheme.setupModuleLightModeData,
      darkTheme: MoabTheme.setupModuleDarkModeData,
      home: MqttPage(),
    );
  }
}

class MqttPage extends StatefulWidget {
  @override
  State<MqttPage> createState() => _MqttPageState();
}

class _MqttPageState extends State<MqttPage> {
  // Local Router simulate endpoint url
  static const _localRouterEndpoint = '18.183.50.91';

  // MQTT default port
  static const _port = 8883;

  // The client id unique to your device
  static const _clientId = 'app1';

  final topics = ['immediately', 'delay/5s', 'delay/10s'];
  final updateTopic = [
    'immediately/response',
    'delay/5s/response',
    'delay/10s/response'
  ];

  final TextEditingController _inputCounterController = TextEditingController();
  bool _isConnected = false;
  bool _isInputValid = false;
  int _counter = 0;
  late MqttClientWrap _client;

  @override
  void initState() {
    super.initState();
    _client = MqttClientWrap(_localRouterEndpoint, _port, _clientId)
      ..connectCallback = () {
        logger.i("Callback: onConnected");
        setState(() {
          _isConnected = true;
        });
        for (var topic in updateTopic) {
          if (!_client.isTopicSubscribe(topic)) {
            _client.subscribe(topic);
          }
        }
      }
      ..disconnectCallback = () {
        logger.i("Callback: onDisconnected");
        setState(() {
          _isConnected = false;
        });
      }
      ..messageReceivedCallback = (topic, payload) {
        logger
            .i("Callback: received message:: topic:$topic, payload:$payload ");
      }
      ..subscribeCallback = (topic) {}
      ..unsubscribeCallback = (topic) {};
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
          alignment: CrossAxisAlignment.start,
          header: const BasicHeader(
            title: 'MQTT',
          ),
          content: _buildContent(),
          footer: Column(
            children: [
              Visibility(
                visible: !_isConnected,
                child: PrimaryButton(
                  text: 'Connect',
                  onPress: !_isConnected
                      ? () {
                          _connectLocal();
                        }
                      : null,
                ),
              ),
              Visibility(
                visible: _isConnected,
                child: SecondaryButton(
                  text: 'Disconnect',
                  onPress: _isConnected
                      ? () {
                          _client.disconnect();
                        }
                      : null,
                ),
              )
            ],
          )),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            const Text('Status:'),
            const SizedBox(
              width: 24,
            ),
            Text(_isConnected ? 'connected' : 'disconnect')
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        Wrap(
          children: [
            const Text('Counter:'),
            const SizedBox(
              width: 24,
            ),
            Text('$_counter')
          ],
        ),
        const SizedBox(
          height: 24,
        ),
        InputField(
            titleText: 'Input counter',
            hintText: '0',
            inputType: TextInputType.number,
            controller: _inputCounterController,
          onChanged: (_) {
              setState(() {
                _validInput();
              });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
                onPressed: _isConnected && _isInputValid
                    ? () {
                        final command = CounterCommand();
                        command.publish(_client, {
                          'id': command.uuid,
                          'counter': int.parse(_inputCounterController.value.text)
                        }).onError((error, stackTrace) {
                          logger.i('VIEW:: receive error: $error');
                          return {};
                        }).then((value) {
                          logger.i('VIEW:: command complete! $value');
                          _handleResult(value);
                        });
                      }
                    : null,
                child: const Text('Immediately')),
            ElevatedButton(
                onPressed: _isConnected && _isInputValid
                    ? () {
                        final command = CounterDelay5Command();
                        command.publish(_client, {
                          'id': command.uuid,
                          'counter': int.parse(_inputCounterController.value.text)
                        }).onError((error, stackTrace) {
                          logger.i('VIEW:: receive error: $error');
                          return {};
                        }).then((value) {
                          logger.i('VIEW:: command complete! $value');
                          _handleResult(value);
                        });
                      }
                    : null,
                child: const Text('Delay 5s')),
            ElevatedButton(
                onPressed: _isConnected && _isInputValid
                    ? () {
                        final command = CounterDelay10Command();
                        command.publish(_client, {
                          'id': command.uuid,
                          'counter': int.parse(_inputCounterController.value.text)
                        }).onError((error, stackTrace) {
                          logger.i('VIEW:: receive error: $error');
                          return {};
                        }).then((value) {
                          logger.i('VIEW:: command complete! $value');
                          _handleResult(value);
                        });
                      }
                    : null,
                child: const Text('Delay 10s')),
          ],
        )
      ],
    );
  }

  void _connectLocal() async {
    final rootCA =
        (await rootBundle.load('assets/keys/local/ca.crt')).buffer.asInt8List();
    final cert = (await rootBundle.load('assets/keys/local/app1.cert.pem'))
        .buffer
        .asInt8List();
    final privateKey =
        (await rootBundle.load('assets/keys/local/app1.private.key'))
            .buffer
            .asInt8List();

    _client
      ..caCert = rootCA
      ..cert = cert
      ..keyCert = privateKey;

    await _client.connect();
  }

  void _validInput() {
    final text = _inputCounterController.value.text;
    if (text.isEmpty) {
      _isInputValid = false;
    } else {
      _isInputValid = int.tryParse(text) != null;
    }

  }

  void _handleResult(Map<String, dynamic> result) {
    int counter = result['counter'] ?? _counter;
    setState(() {
      _counter = counter;
    });
  }
}
