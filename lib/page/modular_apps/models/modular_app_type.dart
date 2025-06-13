enum ModularAppType {
  app,
  user,
  premium,
  ;

  String toValue() {
    switch (this) {
      case ModularAppType.app:
        return 'app';
      case ModularAppType.user:
        return 'user';
      case ModularAppType.premium:
        return 'premium';
    }
  }
}