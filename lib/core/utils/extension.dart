extension MapExt on Map {
  T getValueByPath<T>(String path) {
    final token = path.split('.');
    if (token.length == 1) {
      return this[token[0]];
    } else {
      return (this[token[0]] as Map)
          .getValueByPath<T>(token.sublist(1).join('.'));
    }
  }
}

extension StringExt on String {
  String capitalized() =>
      '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  String camelCapitalized() {
    return split(' ').fold('',
        (previousValue, element) => '$previousValue ${element.capitalized()}');
  }
}
