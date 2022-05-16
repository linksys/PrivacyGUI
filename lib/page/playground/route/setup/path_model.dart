class SetupRoutePath {
  static const setupWelcomeEulaTag = 'welcomeEula';
  static const setupParentTag = 'parentPlug';
  static const setupParentWiredTag = 'parentWired';
  static const setupParentConnectToModemTag = 'parentConnectToModem';
  static const placeParentNodeTag = 'placeParentNode';
  static const setupParentNotHideTag = 'parentNotHide';
  static const setupParentPermissionPrimerTag = 'parentPermissionPrimer';
  static const setupParentScanQRCodeTag = 'parentScanQRCode';
  static const setupParentManualSSIDTag = 'parentManualSSID';
  static const setupParentLocationTag = 'parentLocation';

  static const setupNthChildTag = 'setupNthChild';
  static const setupChildScanQRCode = 'childScanQRCode';
  static const setupNthChildPlugTag = 'nthChildPlug';
  static const setupNthChildLookingTag = 'nthChildLooking';
  static const setupNthChildFoundedTag = 'nthChildFounded';
  static const setupNthChildLocationTag = 'nthChildLocation';
  static const setupNthChildSuccessTag = 'nthChildSuccess';
  static const setupCustomizeWifiSettingsTag = 'customizeWifiSettings';
  static const setupCreateCloudAccountTag = 'createCloudAccount';
  static const setupEnterOTPTag = 'enterOTP';
  static const setupCreateCloudPasswordTag = 'createCloudPassword';
  static const setupCreateCloudAccountSuccessTag = 'createCloudAccountSuccess';
  static const setupCreateAdminPasswordTag = 'createAdminPassword';
  static const setupSaveSettingsTag = 'saveSettings';
  static const setupFinishedTag = 'yourWifiReady';

  static const setupInternetCheckTag = 'internetCheck';
  static const setupInternetCheckFinishedTag = 'internetCheckFinished';
  static const setupChildTag = 'child';
  static const setupUnknown = 'unknown';

  static const setupRootPrefix = '/';
  static const setupWelcomeEulaPrefix = '/$setupWelcomeEulaTag';
  static const setupParentPrefix = '/$setupParentTag';
  static const setupParentWiredPrefix = '/$setupParentWiredTag';
  static const setupParentConnectToModemPrefix =
      '/$setupParentConnectToModemTag';
  static const setupPlaceParentNodePrefix = '/$placeParentNodeTag';
  static const setupParentNotHidePrefix = '/$setupParentNotHideTag';
  static const setupParentPermissionPrimerPrefix =
      '/$setupParentPermissionPrimerTag';
  static const setupParentManualSSIDPrefix = '/$setupParentManualSSIDTag';
  static const setupParentScanQRCodePrefix = '/$setupParentScanQRCodeTag';
  static const setupParentLocationPrefix = '/$setupParentLocationTag';

  static const setupNthChildPrefix = '/$setupNthChildTag';
  static const setupNthchildScanQRCodePrefix = '/$setupChildScanQRCode';
  static const setupNthChildPlugPrefix = '/$setupNthChildPlugTag';
  static const setupNthChildLookingPrefix = '/$setupNthChildLookingTag';
  static const setupNthChildFoundedPrefix = '/$setupNthChildFoundedTag';
  static const setupNthChildLocationPrefix = '/$setupNthChildLocationTag';
  static const setupNthChildSuccessPrefix = '/$setupNthChildSuccessTag';
  static const setupCustomizeWifiSettingsPrefix =
      '/$setupCustomizeWifiSettingsTag';
  static const setupCreateCloudAccountPrefix = '/$setupCreateCloudAccountTag';
  static const setupEnterOTPPrefix = '/$setupEnterOTPTag';
  static const setupCreateCloudPasswordPrefix = '/$setupCreateCloudPasswordTag';
  static const setupCreateAdminPasswordPrefix = '/$setupCreateAdminPasswordTag';
  static const setupCreateCloudAccountSuccessPrefix =
      '/$setupCreateCloudAccountSuccessTag';
  static const setupSaveSettingsPrefix = '/$setupSaveSettingsTag';
  static const setupFinishedPrefix = '/$setupFinishedTag';

  static const setupInternetCheckPrefix = '/$setupInternetCheckTag';
  static const setupInternetCheckFinishedPrefix =
      '/$setupInternetCheckFinishedTag';
  static const setupChildPrefix = '/$setupChildTag';
  static const setupUnknownPrefix = '/$setupUnknown';

  final String path;
  final String history;

  SetupRoutePath.home({String? history})
      : path = setupRootPrefix,
        history = history ?? '';

  SetupRoutePath.welcome({String? history})
      : path = setupWelcomeEulaPrefix,
        history = history ?? '';

  SetupRoutePath.setupParent({String? history})
      : path = setupParentPrefix,
        history = history ?? '';

  SetupRoutePath.setupParentWired({String? history})
      : path = setupParentWiredPrefix,
        history = history ?? '';

  SetupRoutePath.setupConnectToModem({String? history})
      : path = setupParentConnectToModemPrefix,
        history = history ?? '';

  SetupRoutePath.placeParentNode({String? history})
      : path = setupPlaceParentNodePrefix,
        history = history ?? '';

  SetupRoutePath.permissionPrimer({String? history})
      : path = setupParentPermissionPrimerPrefix,
        history = history ?? '';

  SetupRoutePath.parentScan({String? history})
      : path = setupParentScanQRCodePrefix,
        history = history ?? '';

  SetupRoutePath.setupManualParentSSID({String? history})
      : path = setupParentManualSSIDPrefix,
        history = history ?? '';

  SetupRoutePath.setupParentLocation({String? history})
      : path = setupParentLocationPrefix,
        history = history ?? '';

  SetupRoutePath.setupNthChild({String? history})
      : path = setupNthChildPrefix,
        history = history ?? '';

  SetupRoutePath.setupNthChildScanQRCode({String? history})
      : path = setupNthchildScanQRCodePrefix,
        history = history ?? '';

  SetupRoutePath.setupPlugNthChild({String? history})
      : path = setupNthChildPlugPrefix,
        history = history ?? '';

  SetupRoutePath.setupNthChildLooking({String? history})
      : path = setupNthChildLookingPrefix,
        history = history ?? '';

  SetupRoutePath.setupNthChildFounded({String? history})
      : path = setupNthChildFoundedPrefix,
        history = history ?? '';

  SetupRoutePath.setupNthChildLocation({String? history})
      : path = setupNthChildLocationPrefix,
        history = history ?? '';

  SetupRoutePath.setupNthChildSuccess({String? history})
      : path = setupNthChildSuccessPrefix,
        history = history ?? '';

  SetupRoutePath.setupCustomizeWifiSettings({String? history})
      : path = setupCustomizeWifiSettingsPrefix,
        history = history ?? '';

  SetupRoutePath.setupCreateCloudAccount({String? history})
      : path = setupCreateCloudAccountPrefix,
        history = history ?? '';

  SetupRoutePath.setupEnterOTP({String? history})
      : path = setupEnterOTPPrefix,
        history = history ?? '';

  SetupRoutePath.setupCreateCloudPassword({String? history})
      : path = setupCreateCloudPasswordPrefix,
        history = history ?? '';

  SetupRoutePath.setupCreateCloudAccountSuccess({String? history})
      : path = setupCreateCloudAccountSuccessPrefix,
        history = history ?? '';

  SetupRoutePath.setupCreateAdminPassword({String? history})
      : path = setupCreateAdminPasswordPrefix,
        history = history ?? '';

  SetupRoutePath.setupSaveSettings({String? history})
      : path = setupSaveSettingsPrefix,
        history = history ?? '';

  SetupRoutePath.setupFinished({String? history})
      : path = setupFinishedPrefix,
        history = history ?? '';

  SetupRoutePath.setupInternetCheck({String? history})
      : path = setupInternetCheckPrefix,
        history = history ?? '';

  SetupRoutePath.setupInternetCheckFinished({String? history})
      : path = setupInternetCheckFinishedPrefix,
        history = history ?? '';

  SetupRoutePath.setupChild({String? history})
      : path = setupChildPrefix,
        history = history ?? '';

  SetupRoutePath.unknown({String? history})
      : path = setupUnknownPrefix,
        history = history ?? '';
}
