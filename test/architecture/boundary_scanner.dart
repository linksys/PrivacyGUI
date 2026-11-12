/// Finds the dependencies that cross an architecture boundary set by
/// `constitution.md` Article I.
///
/// [sources] maps repo-relative paths (`lib/...`) to Dart source. Each
/// violation reads `<from> -> <to>`.
Set<String> findBoundaryViolations(Map<String, String> sources) {
  final violations = <String>{};
  sources.forEach((path, source) {
    final code = _withoutLineStartComments(source);
    if (_isPresentation(path)) {
      // Constitution 1.2.
      for (final target in _directiveTargets(path, code)) {
        if (_isDataLayer(target)) violations.add('$path -> $target');
      }
      for (final provider in _dataLayerProviders) {
        if (RegExp('\\b$provider\\b').hasMatch(code)) {
          violations.add('$path -> $provider');
        }
      }
    } else if (path.startsWith('lib/core/')) {
      // Constitution 1.3.
      for (final target in _directiveTargets(path, code)) {
        if (target.startsWith('lib/page/')) violations.add('$path -> $target');
      }
    }
  });
  return violations;
}

/// The data layer a presentation file stays away from (constitution 1.2).
bool _isDataLayer(String path) =>
    path == 'lib/core/jnap/router_repository.dart' ||
    path.startsWith('lib/core/jnap/command/') ||
    path.startsWith('lib/core/http/') ||
    path == 'lib/core/cloud/linksys_cloud_repository.dart';

const _dataLayerProviders = [
  'routerRepositoryProvider',
  'cloudRepositoryProvider',
];

/// Directories under `lib/page/` that hold application code (constitution 1.1).
const _applicationDirectories = {
  'providers',
  'service',
  'services',
  'data',
  'models',
  'model',
};

bool _isPresentation(String path) {
  if (!path.startsWith('lib/page/')) return false;
  final directories = path.split('/')..removeLast();
  return !directories.any(_applicationDirectories.contains);
}

/// A comment that starts a line: `//` to the end of the line, or `/*` to the
/// next `*/`. A comment after code is left alone, so that a URL in a string,
/// such as `'http://…'`, cannot hide the rest of its line.
final _lineStartComment =
    RegExp(r'^\s*(?://[^\n]*|/\*[\s\S]*?\*/)', multiLine: true);

String _withoutLineStartComments(String source) =>
    source.replaceAll(_lineStartComment, '');

/// An import or export up to its `;`, conditional URIs included.
final _directive = RegExp(r'^\s*(?:import|export)\b([^;]*);', multiLine: true);
final _uri = RegExp(r'''['"]([^'"]+)['"]''');

const _packagePrefix = 'package:privacy_gui/';

Iterable<String> _directiveTargets(String path, String source) sync* {
  for (final directive in _directive.allMatches(source)) {
    for (final uri in _uri.allMatches(directive.group(1)!)) {
      final target = _resolve(path, uri.group(1)!);
      if (target != null) yield target;
    }
  }
}

/// The repo-relative path [uri] names when imported from [from], or null when
/// it is outside this package (`dart:`, another package).
String? _resolve(String from, String uri) {
  if (uri.startsWith(_packagePrefix)) {
    return 'lib/${uri.substring(_packagePrefix.length)}';
  }
  if (uri.contains(':')) return null;
  final segments = from.split('/')..removeLast();
  for (final segment in uri.split('/')) {
    if (segment == '..') {
      if (segments.isNotEmpty) segments.removeLast();
    } else if (segment != '.') {
      segments.add(segment);
    }
  }
  return segments.join('/');
}
