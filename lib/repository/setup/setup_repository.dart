


import '../model/dummy_model.dart';

abstract class SetupRepository {
  Future<DummyModel> discoverNode();
  Future<DummyModel> fetchNodeInformation();
  Future<void> startPairing(String code);
  Future<void> setLocation(String networkId, String location);
  Future<void> setWiFiCredential(String ssid, String password, int type);
}