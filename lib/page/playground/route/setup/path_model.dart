class SetupRoutePath {
  static const setupWelcomeEulaTag = 'welcomeEula';
  static const setupParentTag = 'parentPlug';
  static const setupParentWiredTag = 'parentWired';
  static const setupParentConnectToModemTag = 'parentConnectToModem';
  static const setupParentNotHideTag = 'parentNotHide';
  static const setupParentPermissionPrimerTag = 'parentPermissionPrimer';

  static const setupInternetCheckTag = 'internetCheck';
  static const setupChildTag = 'child';
  static const setupUnknown = 'unknown';

  static const setupRootPrefix = '/';
  static const setupWelcomeEulaPrefix = '/$setupWelcomeEulaTag';
  static const setupParentPrefix = '/$setupParentTag';
  static const setupParentWiredPrefix = '/$setupParentWiredTag';
  static const setupParentConnectToModemPrefix =
      '/$setupParentConnectToModemTag';
  static const setupParentNotHidePrefix = '/$setupParentNotHideTag';
  static const setupParentPermissionPrimerPrefix =
      '/$setupParentPermissionPrimerTag';

  static const setupInternetCheckPrefix = '/$setupInternetCheckTag';
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

  SetupRoutePath.setupInternetCheck({String? history})
      : path = setupInternetCheckPrefix,
        history = history ?? '';

  SetupRoutePath.setupChild({String? history})
      : path = setupChildPrefix,
        history = history ?? '';

  SetupRoutePath.unknown({String? history})
      : path = setupUnknownPrefix,
        history = history ?? '';
}
