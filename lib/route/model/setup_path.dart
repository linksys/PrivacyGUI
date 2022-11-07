import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/setup/view/_view.dart';
import 'package:linksys_moab/page/setup/view/nodes_not_all_added_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';


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
        return const SetupNodeListView();
      case SetupFinishPath:
        return SetupFinishedView(
          args: args,
        );
      case SetupNodeListPath:
        return SetupNodeListView(
          next: next,
          args: args,
        );
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
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = false;
}

class SetupNodeListPath extends SetupPath {}

class SetupFinishPath extends SetupPath {}

class SetupAddingNodesPath extends SetupPath {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;
}

// Setup Parent Flow
abstract class SetupParentPath extends SetupPath {
  @override
  PageConfig get pageConfig => super.pageConfig..ignoreConnectivityChanged = true;
  
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

class SetupParentLocationPath extends SetupParentPath with ReturnablePath {
  @override
  PageConfig get pageConfig =>
      super.pageConfig..isFullScreenDialog = true;
}

class SetupParentManualEnterSSIDPath extends SetupParentPath {}

class SetupParentConnectWIFIPath extends SetupParentPath {}

class SetupParentEasyConnectWIFIPath extends SetupParentPath {}

class SetupParentLocationPermissionDeniedPath extends SetupParentPath {}

class AndroidLocationPermissionPrimerPath extends SetupParentPath {}

abstract class SetupChildPath extends SetupPath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case SetupNthChildQrCodePath:
        return const AddChildScanQRCodeView();
      case SetupNthChildPlugPath:
        return AddChildPlugView();
      case SetupNthChildSearchingPath:
        return AddChildSearchingView(
          next: next,
          args: args,
        );
      case SetupNthChildLocationPath:
        return const SetLocationView();
      case SetupNthChildPlacePath:
        return PlaceNodeView(
          next: next,
          args: args,
        );
      case NodesDoesntFindPath:
        return NodesDoesntFindView(
          next: next,
          args: args,
        );
      case NodesNotAllAddedPath:
        return NodesNotAllAddedView(
          next: next,
          args: args,
        );
      default:
        return const Center();
    }
  }
}

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

class NodesDoesntFindPath extends SetupChildPath{}
class NodesNotAllAddedPath extends SetupChildPath{}