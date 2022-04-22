import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moab_poc/page/components/qr_view.dart';
import 'package:moab_poc/util/permission.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../channel/wifi_connect_channel.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with Permissions {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  AndroidDeviceInfo? _deviceInfo;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  final _networkInfo = NetworkInfo();
  bool _isScanning = false;
  bool _isLoading = false;
  String _wifiName = '';
  String _gatewayIp = '';
  String _errorMessage = '';
  String _targetSsid = '';
  Timer? _timer;

  void _incrementCounter() async {
    if (Platform.isAndroid) {
      try {
        final result = await NativeConnectWiFiChannel().connectToWiFi('', '');
        log("success: $result");
      } on PlatformException catch (e) {
        log("Error: ${e.message ?? ""}");
        setState(() {
          _errorMessage = e.message ?? "";
          // _isScanning = true;
        });
      }
    } else {
      final permissionResult = await checkCameraPermissions();
      if (permissionResult) {
        setState(() {
          _isScanning = true;
        });
      } else {
        openAppSettings();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _initConnectivity() async {
    final permission = await checkLocationPermissions();
    if (!permission) {
      openAppSettings();
      return;
    }

    final deviceInfo = await _deviceInfoPlugin.androidInfo;
    setState(() {
      _deviceInfo = deviceInfo;
    });

    late ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      log('Couldn\'t check connectivity status', error: e);
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    _updateConnectionStatus(result);
  }

  _updateConnectionStatus(ConnectivityResult result) async {
    _updateNetworkInfo();

    setState(() {
      _connectionStatus = result;
    });
  }

  Future<void> _connectToWiFi(String ssid, String password) async {
    if (Platform.isAndroid) {
      await NativeConnectWiFiChannel().wifiSuggestion(ssid, password);
    } else {
      await NativeConnectWiFiChannel().connectToWiFi(ssid, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _buildContent(context),
      ),
      floatingActionButton: _isLoading && _isScanning
          ? null
          : FloatingActionButton(
              onPressed: _incrementCounter,
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
    );
  }

  // Show AlertDialog
  _showAlertDialog(BuildContext context) {
    // Init
    AlertDialog dialog = AlertDialog(
      title: Text("Seems still can not connect to $_targetSsid!"),
      actions: [
        ElevatedButton(
            child: const Text("Open WiFi Settings"),
            onPressed: () {
              if (Platform.isAndroid) {
                NativeConnectWiFiChannel().openWifiPanel();
              } else {
                openAppSettings();
              }
              Navigator.pop(context);
            }),
      ],
    );
    // Show the dialog
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return dialog;
        });
  }

  Widget _buildContent(BuildContext context) {
    late Widget child;
    if (_isScanning) {
      child = CustomQRView(
        callback: (code) {
          log('QR code: ${code.code}');
          // GetStorage().write("public_key", code.code);
          // Get.back(
          //     result: code.code, id: Get.find<Preferences>().navigationKey);
        },
        onFinish: (code) async {
          log('QR: onFinish: ${code.code}');
          final token = code.code!.split(';');
          final ssid = token[1].replaceAll('S:', '');
          final password = token[2].replaceAll('P:', '');
          log('Parsed WiFI: $ssid, $password');
          setState(() {
            _isScanning = false;
            _targetSsid = ssid;
            _isLoading = true;
          });

          await _connectToWiFi(ssid, password).then((value) {
            if (_timer != null && (_timer?.isActive ?? false)) {
              _timer?.cancel();
            }
            _timer = Timer(const Duration(seconds: 5), () {
              log("Timer Triggered:: $_targetSsid, $_wifiName");
              if (_targetSsid != _wifiName) {
                _showAlertDialog(context);
              }
              setState(() {
                _isLoading = false;
              });
            });
          });
        },
      );
    } else if (_isLoading) {
      child = const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      child = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Press + for testing this device is support Easy Connect or not",
                  style: Theme.of(context).textTheme.headline6,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "You'll see a QR-code scanner if your smart phone support Easy Connect, otherwise you'll see error below.",
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Smartphone Information:",
                        style: Theme.of(context).textTheme.headline6,
                        textAlign: TextAlign.start,
                      ),
                      Text(
                        "Brand: ${_deviceInfo?.brand ?? ""}",
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      Text(
                        "Model: ${_deviceInfo?.model ?? ""}",
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      Text(
                        "Manufacturer: ${_deviceInfo?.manufacturer ?? ""}",
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      Text(
                        "Device: ${_deviceInfo?.device ?? ""}",
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      Text("OS version: ${_deviceInfo?.version.release ?? ""}",
                          style: Theme.of(context).textTheme.subtitle1)
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Current SSID: $_wifiName',
                ),
                Text(
                  'Gateway IP: $_gatewayIp',
                ),
                Text(
                  _errorMessage,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      ?.copyWith(color: Colors.red),
                ),
              ],
            ),
          )),
        ],
      );
    }
    return Center(
      child: child,
    );
  }

  Future<void> _updateNetworkInfo() async {
    String? wifiName,
        wifiBSSID,
        wifiIPv4,
        wifiIPv6,
        wifiGatewayIP,
        wifiBroadcast,
        wifiSubmask;

    try {
      if (!kIsWeb && Platform.isIOS) {
        var status = await _networkInfo.getLocationServiceAuthorization();
        if (status == LocationAuthorizationStatus.notDetermined) {
          status = await _networkInfo.requestLocationServiceAuthorization();
        }
        if (status == LocationAuthorizationStatus.authorizedAlways ||
            status == LocationAuthorizationStatus.authorizedWhenInUse) {
          wifiName = await _networkInfo.getWifiName();
        } else {
          wifiName = await _networkInfo.getWifiName();
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      log('Failed to get Wifi Name', error: e);
      wifiName = 'Failed to get Wifi Name';
    }

    try {
      if (!kIsWeb && Platform.isIOS) {
        var status = await _networkInfo.getLocationServiceAuthorization();
        if (status == LocationAuthorizationStatus.notDetermined) {
          status = await _networkInfo.requestLocationServiceAuthorization();
        }
        if (status == LocationAuthorizationStatus.authorizedAlways ||
            status == LocationAuthorizationStatus.authorizedWhenInUse) {
          wifiBSSID = await _networkInfo.getWifiBSSID();
        } else {
          wifiBSSID = await _networkInfo.getWifiBSSID();
        }
      } else {
        wifiBSSID = await _networkInfo.getWifiBSSID();
      }
    } on PlatformException catch (e) {
      log('Failed to get Wifi BSSID', error: e);
      wifiBSSID = 'Failed to get Wifi BSSID';
    }

    try {
      wifiIPv4 = await _networkInfo.getWifiIP();
    } on PlatformException catch (e) {
      log('Failed to get Wifi IPv4', error: e);
      wifiIPv4 = 'Failed to get Wifi IPv4';
    }

    try {
      wifiIPv6 = await _networkInfo.getWifiIPv6();
    } on PlatformException catch (e) {
      log('Failed to get Wifi IPv6', error: e);
      wifiIPv6 = 'Failed to get Wifi IPv6';
    }

    try {
      wifiSubmask = await _networkInfo.getWifiSubmask();
    } on PlatformException catch (e) {
      log('Failed to get Wifi submask address', error: e);
      wifiSubmask = 'Failed to get Wifi submask address';
    }

    try {
      wifiBroadcast = await _networkInfo.getWifiBroadcast();
    } on PlatformException catch (e) {
      log('Failed to get Wifi broadcast', error: e);
      wifiBroadcast = 'Failed to get Wifi broadcast';
    }

    try {
      wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
    } on PlatformException catch (e) {
      log('Failed to get Wifi gateway address', error: e);
      wifiGatewayIP = 'Failed to get Wifi gateway address';
    }

    try {
      wifiSubmask = await _networkInfo.getWifiSubmask();
    } on PlatformException catch (e) {
      log('Failed to get Wifi submask', error: e);
      wifiSubmask = 'Failed to get Wifi submask';
    }

    setState(() {
      _wifiName = wifiName ?? "";
      _gatewayIp = wifiGatewayIP ?? "";
    });
  }
}
