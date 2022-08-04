
import 'package:linksys_moab/repository/model/dummy_model.dart';
import 'package:linksys_moab/repository/setup/setup_repository.dart';

class FakeSetupRepository extends SetupRepository {
  final waitDuration = const Duration(seconds: 3);
  @override
  Future<DummyModel> discoverNode() {
    // TODO: implement discoverNode
    throw UnimplementedError();
  }

  @override
  Future<DummyModel> fetchNodeInformation() {
    // TODO: implement fetchNodeInformation
    throw UnimplementedError();
  }

  @override
  Future<void> setLocation(String networkId, String location) {
    // TODO: implement setLocation
    throw UnimplementedError();
  }

  @override
  Future<void> setWiFiCredential(String ssid, String password, int type) {
    // TODO: implement setWiFiCredential
    throw UnimplementedError();
  }

  @override
  Future<void> startPairing(String code) {
    // TODO: implement startPairing
    throw UnimplementedError();
  }

}