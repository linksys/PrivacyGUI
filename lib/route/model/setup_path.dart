import 'package:flutter/widgets.dart';
import 'package:moab_poc/page/setup/view/nodes_doesnt_find_view.dart';
import 'package:moab_poc/page/setup/view/view.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/route/route.dart';

import 'base_path.dart';

abstract class SetupPath<P> extends BasePath<P> {

  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case SetupWelcomeEulaPath:
        return GetWiFiUpView();
      case SetupCustomizeSSIDPath:
        return const CustomizeWifiView();
      case SetupNodesDonePath:
        return const NodesSuccessView();
      case SetupFinishPath:
        return SetupFinishedView(args: args,);
      case SetupNodesDoneUnFoundPath:
        return const NodesSuccessView();
      case SetupAddingNodesPath:
        return const AddingNodesView();
      default:
        return const Center();
    }
  }
}

class SetupWelcomeEulaPath extends SetupPath<SetupWelcomeEulaPath> {}

class SetupCustomizeSSIDPath extends SetupPath<SetupCustomizeSSIDPath> {}

class SetupNodesDonePath extends SetupPath<SetupNodesDonePath> {
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;
}

class SetupNodesDoneUnFoundPath extends SetupPath<SetupNodesDoneUnFoundPath> {}

class SetupFinishPath extends SetupPath<SetupFinishPath> {}

class SetupAddingNodesPath extends SetupPath<SetupAddingNodesPath> {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;
}

// Setup Parent Flow
abstract class SetupParentPath<P> extends SetupPath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
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

class SetupParentPlugPath extends SetupParentPath<SetupParentPlugPath> {}

class SetupParentWiredPath extends SetupParentPath<SetupParentWiredPath> {}

class SetupParentPlacePath extends SetupParentPath<SetupParentPlacePath> {}

// TODO revisit - can this being a common page, not for setup specific
class SetupParentPermissionPath
    extends SetupParentPath<SetupParentPermissionPath> {}

class SetupParentQrCodeScanPath
    extends SetupParentPath<SetupParentQrCodeScanPath> {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;
}

class SetupParentManualPath extends SetupParentPath<SetupParentManualPath> {}

class SetupParentLocationPath extends SetupParentPath<SetupParentLocationPath> {
}

class SetupParentManualEnterSSIDPath extends SetupParentPath<SetupParentManualEnterSSIDPath>{}

class SetupParentConnectWIFIPath
    extends SetupParentPath<SetupParentConnectWIFIPath> {}

class SetupParentEasyConnectWIFIPath
    extends SetupParentPath<SetupParentEasyConnectWIFIPath> {}
class SetupParentLocationPermissionDeniedPath extends SetupParentPath<SetupParentLocationPermissionDeniedPath>{}

class AndroidLocationPermissionPrimerPath extends SetupParentPath<AndroidLocationPermissionPrimerPath>{}

// Internet Check Flow
abstract class InternetCheckPath<P> extends SetupPath<P> {
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

abstract class SetupChildPath<P> extends SetupPath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
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
      case NodesDoesntFindPath:
        return const NodesDoesntFindView();
      default:
        return const Center();
    }
  }
}

class SetupNthChildPath extends SetupChildPath<SetupNthChildPath> {}

class SetupNthChildQrCodePath extends SetupChildPath<SetupNthChildQrCodePath> {}

class SetupNthChildPlugPath extends SetupChildPath<SetupNthChildPlugPath> {}

class SetupNthChildSearchingPath
    extends SetupChildPath<SetupNthChildSearchingPath> {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;

  @override
  PageConfig get pageConfig =>
      super.pageConfig..navType = PageNavigationType.none;
}

class SetupNthChildLocationPath
    extends SetupChildPath<SetupNthChildLocationPath> {}

class SetupNthChildPlacePath extends SetupChildPath<SetupNthChildPlacePath> {}

class NodesDoesntFindPath extends SetupChildPath<NodesDoesntFindPath>{}