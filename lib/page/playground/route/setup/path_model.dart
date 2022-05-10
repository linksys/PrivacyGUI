class SetupRoutePath {
  static const setupRootTag = 'setup';
  static const setupParentTag = 'parent';
  static const setupInternetCheckTag = 'internetCheck';
  static const setupChildTag = 'child';
  static const setupUnknown = 'unknown';

  static const setupRootPrefix = '/$setupRootTag';
  static const setupParentPrefix = '$setupRootPrefix/$setupParentTag';
  static const setupInternetCheckPrefix =
      '$setupRootPrefix/$setupInternetCheckTag';
  static const setupChildPrefix = '$setupRootPrefix/$setupChildTag';

  final String path;

  SetupRoutePath.setupParent() : path = setupParentPrefix;
  SetupRoutePath.setupInternetCheck() : path = setupInternetCheckPrefix;
  SetupRoutePath.setupChild() : path = setupChildPrefix;
  SetupRoutePath.unknown() : path = setupUnknown;
}
