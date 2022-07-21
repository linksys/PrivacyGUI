import 'package:flutter/widgets.dart';
import 'package:moab_poc/page/setup/view/view.dart';
import 'package:moab_poc/route/route.dart';

import 'base_path.dart';

abstract class SetupPath<P> extends BasePath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case SetupWelcomeEulaPath:
        return GetWiFiUpView();
      case SetupCustomizeSSIDPath:
        return const CustomizeWifiView();
      case SetupNodesDonePath:
        return const NodesSuccessView();
      case SetupFinishPath:
        return SetupFinishedView(
          args: args,
        );
      case SetupNodesDoneUnFoundPath:
        return const NodesSuccessView();
      case SetupAddingNodesPath:
        return const AddingNodesView();
      default:
        return const Center();
    }
  }
}

class SetupWelcomeEulaPath extends SetupPath {}

class SetupCustomizeSSIDPath extends SetupPath {}

class SetupNodesDonePath extends SetupPath {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;
}

class SetupNodesDoneUnFoundPath extends SetupPath {}

class SetupFinishPath extends SetupPath {}

class SetupAddingNodesPath extends SetupPath {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;
}

// Setup Parent Flow
abstract class SetupParentPath extends SetupPath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case SetupParentPlugPath:
        return PlugNodeView();
      case SetupParentWiredPath:
        return ConnectToModemView();
      case SetupParentPlacePath:
        return PlaceNodeView();
      case SetupParentPermissionPath:
        return PermissionsPrimerView();
      case SetupParentLocationPath:
        return const SetLocationView();
      case SetupParentQrCodeScanPath:
        return const ParentScanQRCodeView();
      case SetupParentConnectWIFIPath:
        return AndroidManuallyConnectView();
      case SetupParentEasyConnectWIFIPath:
        return AndroidQRChoiceView();
      case SetupParentLocationPermissionDeniedPath:
        return const AndroidLocationPermissionDenied();
      case SetupParentManualEnterSSIDPath:
        return const ManualEnterSSIDView();
      case AndroidLocationPermissionPrimerPath:
        return AndroidLocationPermissionPrimer();
      default:
        return const Center();
    }
  }
}

class SetupParentPlugPath extends SetupParentPath {}

class SetupParentWiredPath extends SetupParentPath {}

class SetupParentPlacePath extends SetupParentPath {}

// TODO revisit - can this being a common page, not for setup specific
class SetupParentPermissionPath extends SetupParentPath {}

class SetupParentQrCodeScanPath extends SetupParentPath {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;
}

class SetupParentManualPath extends SetupParentPath {}

class SetupParentLocationPath extends SetupParentPath {}

class SetupParentManualEnterSSIDPath extends SetupParentPath {}

class SetupParentConnectWIFIPath extends SetupParentPath {}

class SetupParentEasyConnectWIFIPath extends SetupParentPath {}

class SetupParentLocationPermissionDeniedPath extends SetupParentPath {}

class AndroidLocationPermissionPrimerPath extends SetupParentPath {}

// Internet Check Flow
abstract class InternetCheckPath<P> extends SetupPath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case InternetCheckingPath:
        return const CheckNodeInternetView();

      default:
        return const Center();
    }
  }
}

class InternetCheckingPath extends InternetCheckPath<InternetCheckingPath> {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;

  @override
  PageConfig get pageConfig =>
      super.pageConfig..navType = PageNavigationType.none;
}

abstract class SetupChildPath extends SetupPath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case SetupNthChildPath:
        return AddChildFinishedView();
      case SetupNthChildQrCodePath:
        return const AddChildScanQRCodeView();
      case SetupNthChildPlugPath:
        return AddChildPlugView();
      case SetupNthChildSearchingPath:
        return const AddChildSearchingView();
      case SetupNthChildLocationPath:
        return const SetLocationView();
      case SetupNthChildPlacePath:
        return PlaceNodeView(
          isAddOnNodes: true,
        );
      default:
        return const Center();
    }
  }
}

class SetupNthChildPath extends SetupChildPath {}

class SetupNthChildQrCodePath extends SetupChildPath {}

class SetupNthChildPlugPath extends SetupChildPath {}

class SetupNthChildSearchingPath extends SetupChildPath {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;

  @override
  PageConfig get pageConfig =>
      super.pageConfig..navType = PageNavigationType.none;
}

class SetupNthChildLocationPath extends SetupChildPath {}

class SetupNthChildPlacePath extends SetupChildPath {}
